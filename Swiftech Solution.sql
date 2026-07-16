CREATE TABLE Employees (
    EmployeeID INT IDENTITY(1,1) PRIMARY KEY,
    FirstName VARCHAR(50) NOT NULL,
    LastName VARCHAR(50) NOT NULL,
    JobTitle VARCHAR(100),
    Department VARCHAR(100),
    Salary DECIMAL(10,2) CHECK (Salary >= 0),
    HireDate DATE NOT NULL
);

CREATE TABLE Clients (
    ClientID INT IDENTITY(1,1) PRIMARY KEY,
    CompanyName VARCHAR(255) NOT NULL,
    ContactName VARCHAR(100),
    Industry VARCHAR(100),
    Email VARCHAR(100) UNIQUE
);

CREATE TABLE Projects (
    ProjectID INT IDENTITY(1,1) PRIMARY KEY,
    ProjectName VARCHAR(255) NOT NULL,
    ClientID INT NOT NULL,
    Budget DECIMAL(12,2) CHECK (Budget >= 0),
    StartDate DATE NOT NULL,
    EndDate DATE,
    FOREIGN KEY (ClientID) REFERENCES Clients(ClientID) ON DELETE CASCADE
);

CREATE TABLE Assignments (
    AssignmentID INT IDENTITY(1,1) PRIMARY KEY,
    EmployeeID INT NOT NULL,
    ProjectID INT NOT NULL,
    Role VARCHAR(100),
    HoursWorked DECIMAL(5,2) CHECK (HoursWorked >= 0),
    FOREIGN KEY (EmployeeID) REFERENCES Employees(EmployeeID) ON DELETE CASCADE,
    FOREIGN KEY (ProjectID) REFERENCES Projects(ProjectID) ON DELETE CASCADE
);

-- Roles Lookup Table
CREATE TABLE Roles_Lookup (
    RoleID INT IDENTITY(1,1) PRIMARY KEY,
    RoleName VARCHAR(100) NOT NULL
);

-- Invoice Status Lookup Table
CREATE TABLE InvoiceStatus_Lookup (
    StatusID INT IDENTITY(1,1) PRIMARY KEY,
    StatusName VARCHAR(50) NOT NULL
);

-- Payment Methods Lookup Table
CREATE TABLE PaymentMethods_Lookup (
    PaymentMethodID INT IDENTITY(1,1) PRIMARY KEY,
    PaymentMethodName VARCHAR(50) NOT NULL
);