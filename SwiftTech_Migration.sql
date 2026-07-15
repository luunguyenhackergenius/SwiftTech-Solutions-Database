-- ============================================================
--  SwiftTech Solutions — Migration Script v1 → v2
--  File: SwiftTech_Migration.sql
--  Author: Luu Nguyen
--
--  Run this against your EXISTING [Swiftech Solution] database
--  to apply the recommended ERD changes without losing data.
--  Safe to run multiple times (uses IF NOT EXISTS guards).
-- ============================================================

USE [Swiftech Solution];
GO

-- ── 1. Add Lookup Tables ─────────────────────────────────────

IF OBJECT_ID('dbo.Roles_Lookup', 'U') IS NULL
BEGIN
    CREATE TABLE Roles_Lookup (
        RoleID   INT          IDENTITY(1,1) PRIMARY KEY,
        RoleName VARCHAR(100) NOT NULL UNIQUE
    );
    PRINT 'Created: Roles_Lookup';
END
GO

IF OBJECT_ID('dbo.InvoiceStatus_Lookup', 'U') IS NULL
BEGIN
    CREATE TABLE InvoiceStatus_Lookup (
        StatusID   INT         IDENTITY(1,1) PRIMARY KEY,
        StatusName VARCHAR(50) NOT NULL UNIQUE
    );
    PRINT 'Created: InvoiceStatus_Lookup';
END
GO

IF OBJECT_ID('dbo.PaymentMethods_Lookup', 'U') IS NULL
BEGIN
    CREATE TABLE PaymentMethods_Lookup (
        PaymentMethodID   INT         IDENTITY(1,1) PRIMARY KEY,
        PaymentMethodName VARCHAR(50) NOT NULL UNIQUE
    );
    PRINT 'Created: PaymentMethods_Lookup';
END
GO

-- ── 2. Seed Lookup Tables ────────────────────────────────────

IF NOT EXISTS (SELECT 1 FROM Roles_Lookup)
BEGIN
    INSERT INTO Roles_Lookup (RoleName) VALUES
        ('Project Manager'), ('Lead Developer'), ('Backend Developer'),
        ('Frontend Developer'), ('QA Engineer'), ('Business Analyst'),
        ('UX Designer'), ('DevOps Engineer');
    PRINT 'Seeded: Roles_Lookup';
END
GO

IF NOT EXISTS (SELECT 1 FROM InvoiceStatus_Lookup)
BEGIN
    INSERT INTO InvoiceStatus_Lookup (StatusName) VALUES
        ('Draft'), ('Sent'), ('Paid'), ('Overdue'), ('Cancelled');
    PRINT 'Seeded: InvoiceStatus_Lookup';
END
GO

IF NOT EXISTS (SELECT 1 FROM PaymentMethods_Lookup)
BEGIN
    INSERT INTO PaymentMethods_Lookup (PaymentMethodName) VALUES
        ('Bank Transfer'), ('Credit Card'), ('Check'), ('PayPal'), ('ACH');
    PRINT 'Seeded: PaymentMethods_Lookup';
END
GO

-- ── 3. Migrate Assignments.Role varchar → RoleID int ─────────
--  Strategy: add new RoleID column, map existing text values to 
--  the lookup table, then drop the old Role column.

IF COL_LENGTH('dbo.Assignments', 'RoleID') IS NULL
BEGIN
    -- Add the new FK column (nullable during migration)
    ALTER TABLE Assignments ADD RoleID INT NULL;

    -- Map existing text roles to lookup IDs (best-effort match)
    UPDATE a
    SET    a.RoleID = r.RoleID
    FROM   Assignments a
    JOIN   Roles_Lookup r
        ON r.RoleName = a.Role          -- exact match where text aligns
    WHERE  a.Role IS NOT NULL;

    -- For any rows that didn't match, default to 'Business Analyst' (ID 6)
    UPDATE Assignments
    SET    RoleID = 6
    WHERE  RoleID IS NULL AND Role IS NOT NULL;

    PRINT 'Added and populated: Assignments.RoleID';
END
GO

-- Add FK constraint on RoleID once data is populated
IF NOT EXISTS (
    SELECT 1 FROM sys.foreign_keys
    WHERE name = 'FK_Assignments_RoleID'
)
BEGIN
    ALTER TABLE Assignments
    ADD CONSTRAINT FK_Assignments_RoleID
        FOREIGN KEY (RoleID) REFERENCES Roles_Lookup(RoleID);
    PRINT 'Added FK: Assignments.RoleID → Roles_Lookup';
END
GO

-- Drop old varchar Role column once migration is confirmed safe
IF COL_LENGTH('dbo.Assignments', 'Role') IS NOT NULL
    AND COL_LENGTH('dbo.Assignments', 'RoleID') IS NOT NULL
BEGIN
    ALTER TABLE Assignments DROP COLUMN Role;
    PRINT 'Dropped: Assignments.Role (varchar) — replaced by RoleID';
END
GO

-- ── 4. Add EmployeeName column (merge FirstName + LastName) ───

IF COL_LENGTH('dbo.Employees', 'EmployeeName') IS NULL
BEGIN
    ALTER TABLE Employees ADD EmployeeName VARCHAR(100) NULL;

    UPDATE Employees
    SET    EmployeeName = LTRIM(RTRIM(FirstName + ' ' + LastName));

    ALTER TABLE Employees ALTER COLUMN EmployeeName VARCHAR(100) NOT NULL;

    PRINT 'Added and populated: Employees.EmployeeName';
END
GO

-- ── 5. Add Invoices Table ────────────────────────────────────

IF OBJECT_ID('dbo.Invoices', 'U') IS NULL
BEGIN
    CREATE TABLE Invoices (
        InvoiceID   INT            IDENTITY(1,1) PRIMARY KEY,
        ClientID    INT            NOT NULL
            REFERENCES Clients(ClientID),
        ProjectID   INT            NOT NULL
            REFERENCES Projects(ProjectID),
        TotalAmount DECIMAL(10, 2) NOT NULL CHECK (TotalAmount >= 0),
        DueDate     DATE           NOT NULL,
        StatusID    INT            NOT NULL
            REFERENCES InvoiceStatus_Lookup(StatusID),
        IssuedDate  DATE           NOT NULL DEFAULT CAST(GETDATE() AS DATE)
    );
    PRINT 'Created: Invoices';
END
GO

-- ── 6. Add Payments Table ────────────────────────────────────

IF OBJECT_ID('dbo.Payments', 'U') IS NULL
BEGIN
    CREATE TABLE Payments (
        PaymentID       INT            IDENTITY(1,1) PRIMARY KEY,
        InvoiceID       INT            NOT NULL
            REFERENCES Invoices(InvoiceID) ON DELETE CASCADE,
        AmountPaid      DECIMAL(10, 2) NOT NULL CHECK (AmountPaid > 0),
        PaymentDate     DATE           NOT NULL DEFAULT CAST(GETDATE() AS DATE),
        PaymentMethodID INT            NOT NULL
            REFERENCES PaymentMethods_Lookup(PaymentMethodID),
        Notes           VARCHAR(255)   NULL
    );
    PRINT 'Created: Payments';
END
GO

PRINT '=== Migration complete. Run verification queries below. ===';
GO

-- ── Verification Queries ─────────────────────────────────────

-- Check all tables exist
SELECT TABLE_NAME
FROM   INFORMATION_SCHEMA.TABLES
WHERE  TABLE_TYPE = 'BASE TABLE'
ORDER  BY TABLE_NAME;
GO

-- Check Assignments columns (should show RoleID, not Role)
SELECT COLUMN_NAME, DATA_TYPE, IS_NULLABLE
FROM   INFORMATION_SCHEMA.COLUMNS
WHERE  TABLE_NAME = 'Assignments'
ORDER  BY ORDINAL_POSITION;
GO

-- Quick data check: assignments with role names resolved
SELECT TOP 5
    a.AssignmentID,
    a.EmployeeID,
    a.ProjectID,
    r.RoleName,
    a.HoursWorked
FROM Assignments a
LEFT JOIN Roles_Lookup r ON a.RoleID = r.RoleID;
GO
