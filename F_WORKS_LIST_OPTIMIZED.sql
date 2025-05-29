CREATE FUNCTION [dbo].[F_WORKS_LIST_OPTIMIZED]()
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
    WITH WorkItemCounts AS (
        SELECT
            Id_Work,
            SUM(CASE WHEN Is_Complit = 0 AND ID_ANALIZ NOT IN (SELECT ID_ANALIZ FROM Analiz WHERE IS_GROUP = 1) THEN 1 ELSE 0 END) AS NotComplit,
            SUM(CASE WHEN Is_Complit = 1 AND ID_ANALIZ NOT IN (SELECT ID_ANALIZ FROM Analiz WHERE IS_GROUP = 1) THEN 1 ELSE 0 END) AS Complit
        FROM WorkItem
        GROUP BY Id_Work
    ),

    EmployeeFIO AS (
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
        ISNULL(wc.NotComplit, 0) AS WorkItemsNotComplit,
        ISNULL(wc.Complit, 0) AS WorkItemsComplit,
        ISNULL(e.FULL_NAME, w.FIO) AS FULL_NAME,
        w.StatusId,
        ws.StatusName,
        CASE WHEN w.Print_Date IS NOT NULL OR w.SendToClientDate IS NOT NULL
                  OR w.SendToDoctorDate IS NOT NULL OR w.SendToOrgDate IS NOT NULL
                  OR w.SendToFax IS NOT NULL
             THEN 1 ELSE 0 END AS Is_Print
    FROM Works w
    LEFT JOIN WorkItemCounts wc ON wc.Id_Work = w.Id_Work
    LEFT JOIN EmployeeFIO e ON e.Id_Employee = w.Id_Employee
    LEFT JOIN WorkStatus ws ON ws.StatusID = w.StatusId
    WHERE w.IS_DEL <> 1
    ORDER BY w.Id_Work DESC

    RETURN
END;
GO
