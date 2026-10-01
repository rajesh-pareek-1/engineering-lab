/* Run this script while connected to master. It is safe to rerun. */
IF DB_ID(N'ArenaSqlPractice') IS NULL
    CREATE DATABASE ArenaSqlPractice;
GO

USE ArenaSqlPractice;
GO

DROP TABLE IF EXISTS dbo.StudentScores;
DROP TABLE IF EXISTS dbo.Users;
DROP TABLE IF EXISTS dbo.Attachments;
DROP TABLE IF EXISTS dbo.Shipments;
DROP TABLE IF EXISTS dbo.Drivers;
DROP TABLE IF EXISTS dbo.Tenants;
GO

CREATE TABLE dbo.Tenants
(
    TenantId   int IDENTITY(1, 1) NOT NULL CONSTRAINT PK_Tenants PRIMARY KEY,
    Name       nvarchar(100) NOT NULL,
    IsActive   bit NOT NULL CONSTRAINT DF_Tenants_IsActive DEFAULT (1),
    CreatedAt  datetime2 NOT NULL CONSTRAINT DF_Tenants_CreatedAt DEFAULT (sysutcdatetime()),
    CONSTRAINT UQ_Tenants_Name UNIQUE (Name)
);

CREATE TABLE dbo.Drivers
(
    DriverId           int IDENTITY(1, 1) NOT NULL CONSTRAINT PK_Drivers PRIMARY KEY,
    TenantId           int NOT NULL,
    FullName           nvarchar(100) NOT NULL,
    Email              nvarchar(150) NOT NULL,
    IsMobileAppEnabled bit NOT NULL,
    IsActive           bit NOT NULL,
    CreatedAt          datetime2 NOT NULL CONSTRAINT DF_Drivers_CreatedAt DEFAULT (sysutcdatetime()),
    CONSTRAINT FK_Drivers_Tenants FOREIGN KEY (TenantId) REFERENCES dbo.Tenants(TenantId)
);

CREATE TABLE dbo.Shipments
(
    ShipmentId int IDENTITY(1, 1) NOT NULL CONSTRAINT PK_Shipments PRIMARY KEY,
    TenantId   int NOT NULL,
    DriverId   int NULL,
    Status     nvarchar(30) NOT NULL,
    Amount     decimal(12, 2) NOT NULL,
    CreatedAt  datetime2 NOT NULL,
    CONSTRAINT FK_Shipments_Tenants FOREIGN KEY (TenantId) REFERENCES dbo.Tenants(TenantId),
    CONSTRAINT FK_Shipments_Drivers FOREIGN KEY (DriverId) REFERENCES dbo.Drivers(DriverId)
);

CREATE TABLE dbo.Attachments
(
    AttachmentId int IDENTITY(1, 1) NOT NULL CONSTRAINT PK_Attachments PRIMARY KEY,
    DriverId     int NOT NULL,
    DocumentType nvarchar(50) NOT NULL,
    BlobPath     nvarchar(250) NOT NULL,
    ExpiryDate   date NULL,
    UploadedAt   datetime2 NOT NULL,
    CONSTRAINT FK_Attachments_Drivers FOREIGN KEY (DriverId) REFERENCES dbo.Drivers(DriverId)
);

/* Deliberately no unique index initially: use this for the duplicate-cleanup drill. */
CREATE TABLE dbo.Users
(
    UserId    int IDENTITY(1, 1) NOT NULL CONSTRAINT PK_Users PRIMARY KEY,
    TenantId  int NOT NULL,
    Email     nvarchar(150) NOT NULL,
    FullName  nvarchar(100) NOT NULL,
    CreatedAt datetime2 NOT NULL CONSTRAINT DF_Users_CreatedAt DEFAULT (sysutcdatetime()),
    CONSTRAINT FK_Users_Tenants FOREIGN KEY (TenantId) REFERENCES dbo.Tenants(TenantId)
);

CREATE TABLE dbo.StudentScores
(
    StudentScoreId int IDENTITY(1, 1) NOT NULL CONSTRAINT PK_StudentScores PRIMARY KEY,
    StudentName    nvarchar(100) NOT NULL,
    ExamYear       int NOT NULL,
    Score          int NOT NULL
);
GO

INSERT dbo.Tenants (Name) VALUES (N'North Haul'), (N'West Logistics'), (N'Feedlot Operations');

INSERT dbo.Drivers (TenantId, FullName, Email, IsMobileAppEnabled, IsActive) VALUES
(1, N'Aarav Singh', N'aarav@north.test', 1, 1),
(1, N'Neha Sharma', N'neha@north.test', 1, 1),
(1, N'Ravi Kumar', N'ravi@north.test', 0, 1),
(2, N'Sana Ali', N'sana@west.test', 1, 1),
(2, N'Mohit Jain', N'mohit@west.test', 1, 0),
(3, N'Divya Rao', N'divya@feedlot.test', 1, 1);

INSERT dbo.Shipments (TenantId, DriverId, Status, Amount, CreatedAt) VALUES
(1, 1, N'Delivered', 1200, '2026-09-01'),
(1, 1, N'InTransit', 700,  '2026-09-03'),
(1, 2, N'Delivered', 1500, '2026-09-04'),
(1, NULL, N'Pending', 500,  '2026-09-05'),
(2, 4, N'Delivered', 2200, '2026-09-02'),
(2, 4, N'Delivered', 800,  '2026-09-08'),
(2, 5, N'Cancelled', 300, '2026-09-09'),
(3, 6, N'InTransit', 900,  '2026-09-10');

INSERT dbo.Attachments (DriverId, DocumentType, BlobPath, ExpiryDate, UploadedAt) VALUES
(1, N'Licence', N'tenants/1/drivers/1/licence-v1.pdf', '2026-10-05', '2026-01-01'),
(1, N'Licence', N'tenants/1/drivers/1/licence-v2.pdf', '2026-11-05', '2026-09-01'),
(1, N'Medical', N'tenants/1/drivers/1/medical.pdf', '2026-09-28', '2026-06-01'),
(2, N'Licence', N'tenants/1/drivers/2/licence.pdf', '2026-09-25', '2026-01-01'),
(4, N'Licence', N'tenants/2/drivers/4/licence.pdf', '2027-02-01', '2026-01-01'),
(6, N'Other', N'tenants/3/drivers/6/other.pdf', NULL, '2026-04-01');

INSERT dbo.Users (TenantId, Email, FullName, CreatedAt) VALUES
(1, N'ops@north.test', N'North Ops', '2026-01-01'),
(1, N'ops@north.test', N'North Ops Duplicate', '2026-01-02'),
(2, N'admin@west.test', N'West Admin', '2026-01-01'),
(2, N'admin@west.test', N'West Admin Duplicate', '2026-01-03'),
(3, N'admin@feedlot.test', N'Feedlot Admin', '2026-01-01');

INSERT dbo.StudentScores (StudentName, ExamYear, Score) VALUES
(N'Anaya', 2017, 71), (N'Anaya', 2018, 74), (N'Anaya', 2019, 69),
(N'Anaya', 2020, 82), (N'Anaya', 2021, 88), (N'Anaya', 2022, 84),
(N'Anaya', 2023, 91), (N'Anaya', 2024, 94), (N'Anaya', 2025, 90), (N'Anaya', 2026, 96),
(N'Kabir', 2025, 89), (N'Mira', 2025, 95), (N'Arjun', 2025, 89);
GO

SELECT N'Practice database ready' AS Result, DB_NAME() AS DatabaseName;

