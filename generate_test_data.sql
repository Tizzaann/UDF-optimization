SET NOCOUNT ON;
DECLARE @i INT = 1;
WHILE @i <= 100
BEGIN
    INSERT INTO Employee (Login_Name, Name, Patronymic, Surname, Email, Post, Archived, IS_Role)
    VALUES ('user' + CAST(@i AS VARCHAR), 'Имя' + CAST(@i AS VARCHAR), 'Отчество' + CAST(@i AS VARCHAR), 'Фамилия' + CAST(@i AS VARCHAR),
            'user' + CAST(@i AS VARCHAR) + '@mail.com', 'Должность', 0, 0);
    SET @i += 1;
END


SET @i = 1;
WHILE @i <= 100
BEGIN
    INSERT INTO Analiz (IS_GROUP, MATERIAL_TYPE, CODE_NAME, FULL_NAME, Price)
    VALUES (0, 1, 'A' + CAST(@i AS VARCHAR), 'Анализ ' + CAST(@i AS VARCHAR), 500 + @i);
    SET @i += 1;
END


DECLARE @employee_count INT = (SELECT COUNT(*) FROM Employee);
DECLARE @org_id INT = NULL;

SET @i = 1;
WHILE @i <= 50000
BEGIN
    INSERT INTO Works (IS_Complit, CREATE_Date, Id_Employee, FIO, Is_Del, MaterialNumber)
    VALUES (0, DATEADD(DAY, -(@i % 365), GETDATE()), 1 + ABS(CHECKSUM(NEWID())) % @employee_count,
            'Пациент ' + CAST(@i AS VARCHAR), 0, @i);
    SET @i += 1;
END


DECLARE @work_id INT = 1;
WHILE @work_id <= 50000
BEGIN
    DECLARE @j INT = 1;
    DECLARE @items_per_order INT = 2 + ABS(CHECKSUM(NEWID())) % 3;
    WHILE @j <= @items_per_order
    BEGIN
        INSERT INTO WorkItem (CREATE_DATE, Is_Complit, Id_Employee, ID_ANALIZ, Id_Work, Is_Print, Is_Select)
        VALUES (GETDATE(), ABS(CHECKSUM(NEWID())) % 2,
                1 + ABS(CHECKSUM(NEWID())) % @employee_count,
                1 + ABS(CHECKSUM(NEWID())) % 100,
                @work_id, 1, 0);
        SET @j += 1;
    END
    SET @work_id += 1;
END