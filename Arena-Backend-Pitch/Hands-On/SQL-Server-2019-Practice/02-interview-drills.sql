USE ArenaSqlPractice;
GO

/*
RULE: attempt each question first. The answer starts immediately under its question.
Use "Include Actual Execution Plan" in VS Code/SSMS for drills 9-11.
*/

-- 1. INNER JOIN: show every assigned shipment with driver and tenant name.
SELECT s.ShipmentId, t.Name AS Tenant, d.FullName AS Driver, s.Status, s.Amount
FROM dbo.Shipments AS s
INNER JOIN dbo.Drivers AS d ON d.DriverId = s.DriverId
INNER JOIN dbo.Tenants AS t ON t.TenantId = s.TenantId;

-- 2. LEFT JOIN: show all drivers, including drivers with no shipment.
SELECT d.FullName, s.ShipmentId, s.Status
FROM dbo.Drivers AS d
LEFT JOIN dbo.Shipments AS s ON s.DriverId = d.DriverId;

-- 3. GROUP BY + HAVING: tenants whose delivered-shipment total exceeds 1,500.
SELECT t.Name, SUM(s.Amount) AS DeliveredAmount
FROM dbo.Shipments AS s
INNER JOIN dbo.Tenants AS t ON t.TenantId = s.TenantId
WHERE s.Status = N'Delivered'
GROUP BY t.Name
HAVING SUM(s.Amount) > 1500;

-- 4. CASE: label each expiry record as Expired / Due soon / Valid / No expiry.
SELECT a.DocumentType, d.FullName, a.ExpiryDate,
       CASE
           WHEN a.ExpiryDate IS NULL THEN N'No expiry'
           WHEN a.ExpiryDate < CAST(GETDATE() AS date) THEN N'Expired'
           WHEN a.ExpiryDate <= DATEADD(day, 30, CAST(GETDATE() AS date)) THEN N'Due soon'
           ELSE N'Valid'
       END AS ExpiryStatus
FROM dbo.Attachments AS a
INNER JOIN dbo.Drivers AS d ON d.DriverId = a.DriverId;

-- 5. CTE + ROW_NUMBER: retain newest user per tenant/email, then preview duplicates.
WITH RankedUsers AS
(
    SELECT UserId, TenantId, Email, CreatedAt,
           ROW_NUMBER() OVER (PARTITION BY TenantId, Email ORDER BY CreatedAt DESC) AS RowNumber
    FROM dbo.Users
)
SELECT * FROM RankedUsers WHERE RowNumber > 1;

-- 6. DELETE duplicates safely: first run the CTE as SELECT, then change SELECT to DELETE.
BEGIN TRANSACTION;
WITH RankedUsers AS
(
    SELECT UserId,
           ROW_NUMBER() OVER (PARTITION BY TenantId, Email ORDER BY CreatedAt DESC) AS RowNumber
    FROM dbo.Users
)
DELETE FROM RankedUsers WHERE RowNumber > 1;
SELECT * FROM dbo.Users ORDER BY TenantId, Email, CreatedAt;
ROLLBACK TRANSACTION; -- Change to COMMIT only after verifying business rule and taking a backup.

-- 7. Rank 2025 students: RANK leaves gaps; DENSE_RANK does not.
SELECT StudentName, Score,
       RANK()       OVER (ORDER BY Score DESC) AS [Rank],
       DENSE_RANK() OVER (ORDER BY Score DESC) AS DenseRank
FROM dbo.StudentScores
WHERE ExamYear = 2025;

-- 8. LAG: compare a student's result with the previous year. This answers the “last 10 years” interview question.
SELECT StudentName, ExamYear, Score,
       LAG(Score) OVER (PARTITION BY StudentName ORDER BY ExamYear) AS PreviousScore,
       Score - LAG(Score) OVER (PARTITION BY StudentName ORDER BY ExamYear) AS ChangeFromPreviousYear
FROM dbo.StudentScores
WHERE StudentName = N'Anaya'
ORDER BY ExamYear;

-- 9. ROD-style latest document of each type, without loading every attachment into application memory.
WITH LatestDocument AS
(
    SELECT a.*, ROW_NUMBER() OVER
    (
        PARTITION BY a.DriverId, a.DocumentType
        ORDER BY a.UploadedAt DESC, a.AttachmentId DESC
    ) AS RowNumber
    FROM dbo.Attachments AS a
    WHERE a.ExpiryDate IS NOT NULL
)
SELECT d.FullName, ld.DocumentType, ld.ExpiryDate
FROM LatestDocument AS ld
INNER JOIN dbo.Drivers AS d ON d.DriverId = ld.DriverId
WHERE ld.RowNumber = 1
  AND d.IsMobileAppEnabled = 1
  AND d.IsActive = 1;

-- 10. Create the index after looking at the plan for Drill 9.
CREATE INDEX IX_Attachments_Driver_Document_Uploaded
ON dbo.Attachments (DriverId, DocumentType, UploadedAt DESC)
INCLUDE (ExpiryDate);

-- 11. Composite index for the common “tenant + status + newest first” shipment screen.
CREATE INDEX IX_Shipments_Tenant_Status_CreatedAt
ON dbo.Shipments (TenantId, Status, CreatedAt DESC)
INCLUDE (DriverId, Amount);

-- 12. SARGable: index can seek. Do not wrap the indexed CreatedAt column in a function.
DECLARE @Start datetime2 = '2026-09-01';
DECLARE @End   datetime2 = '2026-10-01';

SELECT ShipmentId, Status, Amount
FROM dbo.Shipments
WHERE TenantId = 1
  AND CreatedAt >= @Start
  AND CreatedAt < @End;

-- Bad shape (typically prevents a seek): WHERE CAST(CreatedAt AS date) = '2026-09-01'

-- 13. 8th highest distinct score. Return no row if fewer than eight distinct scores exist.
WITH RankedScores AS
(
    SELECT Score, DENSE_RANK() OVER (ORDER BY Score DESC) AS ScoreRank
    FROM dbo.StudentScores
)
SELECT DISTINCT Score FROM RankedScores WHERE ScoreRank = 8;
