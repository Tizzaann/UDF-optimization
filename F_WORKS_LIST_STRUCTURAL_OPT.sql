ALTER TABLE Works ADD
    Cached_WorkItems_Complit INT NULL,
    Cached_WorkItems_NotComplit INT NULL;
GO


CREATE TRIGGER TRG_Update_WorkItem_Counts
ON WorkItem
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @UpdatedWorks TABLE (Id_Work INT);

    INSERT INTO @UpdatedWorks
    SELECT DISTINCT Id_Work FROM (
        SELECT Id_Work FROM inserted
        UNION
        SELECT Id_Work FROM deleted
    ) AS w WHERE Id_Work IS NOT NULL;

    UPDATE w
    SET
        Cached_WorkItems_NotComplit = x.NotComplit,
        Cached_WorkItems_Complit = x.Complit
    FROM Works w
    JOIN (
        SELECT
            wi.Id_Work,
            SUM(CASE WHEN wi.Is_Complit = 0 AND a.IS_GROUP = 0 THEN 1 ELSE 0 END) AS NotComplit,
            SUM(CASE WHEN wi.Is_Complit = 1 AND a.IS_GROUP = 0 THEN 1 ELSE 0 END) AS Complit
        FROM WorkItem wi
        JOIN Analiz a ON a.ID_ANALIZ = wi.ID_ANALIZ
        WHERE wi.Id_Work IN (SELECT Id_Work FROM @UpdatedWorks)
        GROUP BY wi.Id_Work
    ) x ON x.Id_Work = w.Id_Work;
END;
GO


UPDATE w
SET
    Cached_WorkItems_NotComplit = x.NotComplit,
    Cached_WorkItems_Complit = x.Complit
FROM Works w
JOIN (
    SELECT
        wi.Id_Work,
        SUM(CASE WHEN wi.Is_Complit = 0 AND a.IS_GROUP = 0 THEN 1 ELSE 0 END) AS NotComplit,
        SUM(CASE WHEN wi.Is_Complit = 1 AND a.IS_GROUP = 0 THEN 1 ELSE 0 END) AS Complit
    FROM WorkItem wi
    JOIN Analiz a ON a.ID_ANALIZ = wi.ID_ANALIZ
    GROUP BY wi.Id_Work
) x ON x.Id_Work = w.Id_Work;
GO


CREATE FUNCTION [dbo].[F_WORKS_LIST_STRUCTURAL_OPT]()
RETURNS @RESULT TABLE
(
    ID_WORK INT,
    CREATE_Date DATETIME,
    MaterialNumber DECIMAL(8,2),
    IS_Complit BIT,
    FIO VARCHAR(255),
    D_DATE VARCHAR(10),
    WorkItemsNotComplit INT,
    WorkItemsComplit INT,
    FULL_NAME VARCHAR(101),
    StatusId SMALLINT,
    StatusName VARCHAR(255),
    Is_Print BIT
)
AS
BEGIN
    WITH EmployeeFIO AS (
        SELECT
            Id_Employee,
            Surname + ' ' + UPPER(LEFT(Name, 1)) + '. ' + UPPER(LEFT(Patronymic, 1)) + '.' AS FULL_NAME
        FROM Employee
    )

    INSERT INTO @RESULT
    SELECT
        w.Id_Work,
        w.CREATE_Date,
        w.MaterialNumber,
        w.IS_Complit,
        w.FIO,
        CONVERT(VARCHAR(10), w.CREATE_Date, 104) AS D_DATE,
        ISNULL(w.Cached_WorkItems_NotComplit, 0),
        ISNULL(w.Cached_WorkItems_Complit, 0),
        ISNULL(e.FULL_NAME, w.FIO),
        w.StatusId,
        ws.StatusName,
        CASE WHEN w.Print_Date IS NOT NULL OR w.SendToClientDate IS NOT NULL
                  OR w.SendToDoctorDate IS NOT NULL OR w.SendToOrgDate IS NOT NULL
                  OR w.SendToFax IS NOT NULL THEN 1 ELSE 0 END AS Is_Print
    FROM Works w
    LEFT JOIN EmployeeFIO e ON e.Id_Employee = w.Id_Employee
    LEFT JOIN WorkStatus ws ON ws.StatusID = w.StatusId
    WHERE w.IS_DEL <> 1
    ORDER BY w.Id_Work DESC

    RETURN
END;
GO
