-- ============================================================
--  SwiftTech Solutions — Database v2 (Recommended Changes)
--  File: SwiftTech_Updated.sql
--  Author: Luu Nguyen
--
--  This script implements the instructor-recommended ERD changes:
--    1. Add Roles_Lookup, InvoiceStatus_Lookup, PaymentMethods_Lookup
--    2. Refactor Assignments.Role from varchar → int FK
--    3. Add Invoices table (linked to Clients + Projects)
--    4. Add Payments table (linked to Invoices + PaymentMethods_Lookup)
--    5. Merge Employee FirstName/LastName → EmployeeName
-- ============================================================

USE [master];
GO

-- Drop and recreate for a clean run
IF DB_ID('SwiftTech_v2') IS NOT NULL
    DROP DATABASE [SwiftTech_v2];
GO

CREATE DATABASE [SwiftTech_v2];
GO

USE [SwiftTech_v2];
GO

-- ──────────────────────────────────────────────────────────────
--  STEP 1 — Lookup Tables
--  These replace hard-coded strings with controlled reference data,
--  making reports consistent and values easy to update in one place.
-- ──────────────────────────────────────────────────────────────

-- Replaces the free-text Role column in Assignments
CREATE TABLE Roles_Lookup (
    RoleID   INT          IDENTITY(1,1) PRIMARY KEY,
    RoleName VARCHAR(100) NOT NULL UNIQUE
);

-- Controls the Status column in Invoices
CREATE TABLE InvoiceStatus_Lookup (
    StatusID   INT         IDENTITY(1,1) PRIMARY KEY,
    StatusName VARCHAR(50) NOT NULL UNIQUE
);

-- Controls the PaymentMethod column in Payments
CREATE TABLE PaymentMethods_Lookup (
    PaymentMethodID   INT         IDENTITY(1,1) PRIMARY KEY,
    PaymentMethodName VARCHAR(50) NOT NULL UNIQUE
);
GO


-- ──────────────────────────────────────────────────────────────
--  STEP 2 — Core Tables (updated from original)
-- ──────────────────────────────────────────────────────────────

-- Employees: merged FirstName + LastName → EmployeeName (as per ERD)
CREATE TABLE Employees (
    EmployeeID   INT            IDENTITY(1,1) PRIMARY KEY,
    EmployeeName VARCHAR(100)   NOT NULL,          -- was FirstName + LastName
    JobTitle     VARCHAR(100)   NULL,
    Department   VARCHAR(100)   NULL,
    Salary       DECIMAL(10, 2) NULL CHECK (Salary >= 0),
    HireDate     DATE           NOT NULL
);

-- Clients: unchanged from original
CREATE TABLE Clients (
    ClientID     INT          IDENTITY(1,1) PRIMARY KEY,
    CompanyName  VARCHAR(255) NOT NULL,
    ContactName  VARCHAR(100) NULL,
    Industry     VARCHAR(100) NULL,
    Email        VARCHAR(100) NULL UNIQUE
);

-- Projects: unchanged from original
CREATE TABLE Projects (
    ProjectID   INT            IDENTITY(1,1) PRIMARY KEY,
    ProjectName VARCHAR(255)   NOT NULL,
    ClientID    INT            NOT NULL
        REFERENCES Clients(ClientID) ON DELETE CASCADE,
    Budget      DECIMAL(12, 2) NULL CHECK (Budget >= 0),
    StartDate   DATE           NOT NULL,
    EndDate     DATE           NULL
);

-- Assignments: Role changed from VARCHAR → INT FK to Roles_Lookup
CREATE TABLE Assignments (
    AssignmentID INT            IDENTITY(1,1) PRIMARY KEY,
    EmployeeID   INT            NOT NULL
        REFERENCES Employees(EmployeeID) ON DELETE CASCADE,
    ProjectID    INT            NOT NULL
        REFERENCES Projects(ProjectID)  ON DELETE CASCADE,
    RoleID       INT            NULL           -- was: Role VARCHAR(100)
        REFERENCES Roles_Lookup(RoleID),
    HoursWorked  DECIMAL(5, 2)  NULL CHECK (HoursWorked >= 0)
);
GO


-- ──────────────────────────────────────────────────────────────
--  STEP 3 — New Tables: Invoices and Payments
--  These were not in the original schema and represent the main
--  addition in the recommended ERD.
-- ──────────────────────────────────────────────────────────────

-- Invoices: one invoice per project, billed to the client
CREATE TABLE Invoices (
    InvoiceID    INT            IDENTITY(1,1) PRIMARY KEY,
    ClientID     INT            NOT NULL
        REFERENCES Clients(ClientID)  ON DELETE NO ACTION,
    ProjectID    INT            NOT NULL
        REFERENCES Projects(ProjectID) ON DELETE NO ACTION,
    TotalAmount  DECIMAL(10, 2) NOT NULL CHECK (TotalAmount >= 0),
    DueDate      DATE           NOT NULL,
    StatusID     INT            NOT NULL          -- FK replaces Status VARCHAR
        REFERENCES InvoiceStatus_Lookup(StatusID),
    IssuedDate   DATE           NOT NULL DEFAULT CAST(GETDATE() AS DATE)
);

-- Payments: one or more payments can be made against an invoice
CREATE TABLE Payments (
    PaymentID       INT            IDENTITY(1,1) PRIMARY KEY,
    InvoiceID       INT            NOT NULL
        REFERENCES Invoices(InvoiceID) ON DELETE CASCADE,
    AmountPaid      DECIMAL(10, 2) NOT NULL CHECK (AmountPaid > 0),
    PaymentDate     DATE           NOT NULL DEFAULT CAST(GETDATE() AS DATE),
    PaymentMethodID INT            NOT NULL       -- FK to lookup
        REFERENCES PaymentMethods_Lookup(PaymentMethodID),
    Notes           VARCHAR(255)   NULL
);
GO


-- ──────────────────────────────────────────────────────────────
--  STEP 4 — Seed Lookup Tables
--  Populate reference data first so FKs resolve in the data load.
-- ──────────────────────────────────────────────────────────────

INSERT INTO Roles_Lookup (RoleName) VALUES
    ('Project Manager'),
    ('Lead Developer'),
    ('Backend Developer'),
    ('Frontend Developer'),
    ('QA Engineer'),
    ('Business Analyst'),
    ('UX Designer'),
    ('DevOps Engineer');

INSERT INTO InvoiceStatus_Lookup (StatusName) VALUES
    ('Draft'),
    ('Sent'),
    ('Paid'),
    ('Overdue'),
    ('Cancelled');

INSERT INTO PaymentMethods_Lookup (PaymentMethodName) VALUES
    ('Bank Transfer'),
    ('Credit Card'),
    ('Check'),
    ('PayPal'),
    ('ACH');
GO


-- ──────────────────────────────────────────────────────────────
--  STEP 5 — Seed Core Tables
-- ──────────────────────────────────────────────────────────────

INSERT INTO Employees (EmployeeName, JobTitle, Department, Salary, HireDate) VALUES
    ('Marcus Bell',     'CTO',                  'Engineering',  145000.00, '2019-03-12'),
    ('Priya Sharma',    'Project Manager',       'Operations',   95000.00,  '2020-06-01'),
    ('Derek Liu',       'Lead Developer',        'Engineering',  110000.00, '2020-09-15'),
    ('Aisha Nwosu',     'QA Engineer',           'Engineering',  78000.00,  '2021-02-08'),
    ('James Ortega',    'Business Analyst',      'Operations',   82000.00,  '2021-07-19'),
    ('Sofia Bauer',     'Frontend Developer',    'Engineering',  88000.00,  '2022-01-10'),
    ('Theo Campbell',   'Backend Developer',     'Engineering',  92000.00,  '2022-04-25'),
    ('Rachel Kim',      'UX Designer',           'Design',       85000.00,  '2022-08-01'),
    ('Omar Hassan',     'DevOps Engineer',       'Engineering',  99000.00,  '2023-01-16'),
    ('Lena Petrov',     'Project Manager',       'Operations',   94000.00,  '2023-05-30');

INSERT INTO Clients (CompanyName, ContactName, Industry, Email) VALUES
    ('Apex Logistics',       'Tom Reynolds',    'Logistics',          'tom.r@apexlogistics.com'),
    ('BrightPath Health',    'Sandra Lee',      'Healthcare',         's.lee@brightpathhealth.com'),
    ('CoreFinance Group',    'Alan Brooks',     'Finance',            'a.brooks@corefinance.com'),
    ('DataEdge Analytics',   'Nadia Voss',      'Technology',         'n.voss@dataedge.io'),
    ('EcoVentures Inc.',     'Mark Huang',      'Environmental',      'm.huang@ecoventures.com');

INSERT INTO Projects (ProjectName, ClientID, Budget, StartDate, EndDate) VALUES
    ('Logistics Portal Redesign',        1, 120000.00, '2023-02-01', '2023-07-31'),
    ('Patient Records System',           2, 250000.00, '2023-03-15', '2023-12-31'),
    ('Financial Reporting Dashboard',    3,  85000.00, '2023-05-01', '2023-10-15'),
    ('Data Pipeline Automation',         4, 175000.00, '2023-06-10', '2024-01-31'),
    ('Carbon Tracking App',              5,  60000.00, '2023-09-01', '2024-03-31'),
    ('Mobile CRM Integration',           1,  95000.00, '2024-01-15', NULL);

INSERT INTO Assignments (EmployeeID, ProjectID, RoleID, HoursWorked) VALUES
    (2,  1, 1, 210.00),   -- Priya: Project Manager on Project 1
    (3,  1, 2, 380.50),   -- Derek: Lead Developer
    (6,  1, 4, 290.00),   -- Sofia: Frontend Developer
    (4,  1, 5, 120.00),   -- Aisha: QA Engineer
    (2,  2, 1, 180.00),   -- Priya: Project Manager on Project 2
    (7,  2, 3, 420.00),   -- Theo: Backend Developer
    (8,  2, 7,  95.00),   -- Rachel: UX Designer
    (4,  2, 5, 160.00),   -- Aisha: QA Engineer
    (5,  3, 6, 210.00),   -- James: Business Analyst on Project 3
    (3,  3, 2, 310.00),   -- Derek: Lead Developer
    (6,  3, 4, 175.00),   -- Sofia: Frontend Developer
    (9,  4, 8, 280.00),   -- Omar: DevOps Engineer on Project 4
    (7,  4, 3, 390.00),   -- Theo: Backend Developer
    (5,  4, 6, 140.00),   -- James: Business Analyst
    (10, 5, 1, 190.00),   -- Lena: Project Manager on Project 5
    (6,  5, 4, 220.00),   -- Sofia: Frontend Developer
    (8,  5, 7, 110.00),   -- Rachel: UX Designer
    (10, 6, 1,  80.00),   -- Lena: Project Manager on Project 6
    (3,  6, 2, 150.00),   -- Derek: Lead Developer
    (9,  6, 8,  60.00);   -- Omar: DevOps Engineer
GO


-- ──────────────────────────────────────────────────────────────
--  STEP 6 — Seed Invoices and Payments
-- ──────────────────────────────────────────────────────────────

-- StatusID: 1=Draft, 2=Sent, 3=Paid, 4=Overdue, 5=Cancelled
INSERT INTO Invoices (ClientID, ProjectID, TotalAmount, DueDate, StatusID, IssuedDate) VALUES
    (1, 1, 118500.00, '2023-08-31', 3, '2023-08-01'),  -- Paid
    (2, 2, 248000.00, '2024-01-31', 3, '2024-01-01'),  -- Paid
    (3, 3,  84000.00, '2023-11-15', 3, '2023-10-20'),  -- Paid
    (4, 4, 172000.00, '2024-02-28', 4, '2024-01-31'),  -- Overdue
    (5, 5,  59500.00, '2024-04-30', 2, '2024-03-31'),  -- Sent
    (1, 6,  40000.00, '2024-06-30', 1, '2024-05-15');  -- Draft (partial, ongoing)

-- PaymentMethodID: 1=Bank Transfer, 2=Credit Card, 3=Check, 4=PayPal, 5=ACH
INSERT INTO Payments (InvoiceID, AmountPaid, PaymentDate, PaymentMethodID, Notes) VALUES
    (1,  60000.00, '2023-08-15', 1, '50% deposit on project completion'),
    (1,  58500.00, '2023-08-30', 1, 'Final payment — project signed off'),
    (2, 100000.00, '2023-12-01', 5, 'Milestone 1 payment'),
    (2, 100000.00, '2024-01-10', 5, 'Milestone 2 payment'),
    (2,  48000.00, '2024-01-28', 5, 'Final payment'),
    (3,  84000.00, '2023-11-10', 2, 'Full payment via credit card'),
    (5,  20000.00, '2024-04-01', 1, 'Partial advance payment');
GO


-- ──────────────────────────────────────────────────────────────
--  STEP 7 — Useful Reporting Queries
--  Run these after seeding to verify the new schema works.
-- ──────────────────────────────────────────────────────────────

-- Q1: All assignments with readable role names (verifies the FK refactor)
SELECT
    e.EmployeeName,
    p.ProjectName,
    r.RoleName,
    a.HoursWorked
FROM Assignments   a
JOIN Employees     e ON a.EmployeeID = e.EmployeeID
JOIN Projects      p ON a.ProjectID  = p.ProjectID
LEFT JOIN Roles_Lookup r ON a.RoleID = r.RoleID
ORDER BY p.ProjectName, e.EmployeeName;
GO

-- Q2: Invoice summary with client, project, and status name
SELECT
    c.CompanyName,
    p.ProjectName,
    i.TotalAmount,
    i.DueDate,
    s.StatusName,
    i.IssuedDate
FROM Invoices            i
JOIN Clients             c ON i.ClientID  = c.ClientID
JOIN Projects            p ON i.ProjectID = p.ProjectID
JOIN InvoiceStatus_Lookup s ON i.StatusID = s.StatusID
ORDER BY i.DueDate;
GO

-- Q3: Payment history with method names and running total per invoice
SELECT
    i.InvoiceID,
    c.CompanyName,
    i.TotalAmount,
    pm.PaymentMethodName,
    pay.AmountPaid,
    pay.PaymentDate,
    SUM(pay.AmountPaid) OVER (
        PARTITION BY pay.InvoiceID
        ORDER BY pay.PaymentDate
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS RunningTotal
FROM Payments               pay
JOIN Invoices               i  ON pay.InvoiceID       = i.InvoiceID
JOIN Clients                c  ON i.ClientID           = c.ClientID
JOIN PaymentMethods_Lookup pm  ON pay.PaymentMethodID  = pm.PaymentMethodID
ORDER BY pay.InvoiceID, pay.PaymentDate;
GO

-- Q4: Outstanding balance per invoice (TotalAmount minus sum of payments)
SELECT
    c.CompanyName,
    p.ProjectName,
    i.TotalAmount,
    ISNULL(SUM(pay.AmountPaid), 0)                          AS TotalPaid,
    i.TotalAmount - ISNULL(SUM(pay.AmountPaid), 0)          AS OutstandingBalance,
    s.StatusName
FROM Invoices               i
JOIN Clients                c  ON i.ClientID  = c.ClientID
JOIN Projects               p  ON i.ProjectID = p.ProjectID
JOIN InvoiceStatus_Lookup   s  ON i.StatusID  = s.StatusID
LEFT JOIN Payments         pay ON i.InvoiceID = pay.InvoiceID
GROUP BY c.CompanyName, p.ProjectName, i.TotalAmount, s.StatusName
ORDER BY OutstandingBalance DESC;
GO

-- Q5: Hours worked per employee across all projects, ranked by contribution
SELECT
    e.EmployeeName,
    e.Department,
    COUNT(DISTINCT a.ProjectID)             AS ProjectCount,
    ROUND(SUM(a.HoursWorked), 2)           AS TotalHours,
    RANK() OVER (ORDER BY SUM(a.HoursWorked) DESC) AS HoursRank
FROM Assignments a
JOIN Employees   e ON a.EmployeeID = e.EmployeeID
GROUP BY e.EmployeeName, e.Department
ORDER BY TotalHours DESC;
GO
