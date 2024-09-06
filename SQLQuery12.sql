USE HMAcademy12_08_2024;

-- 1. Факультети (Faculties)
CREATE TABLE Faculties (
    Id INT PRIMARY KEY IDENTITY(1,1),
    Financing MONEY NOT NULL CHECK (Financing >= 0) DEFAULT 0,
    Name NVARCHAR(100) NOT NULL UNIQUE CHECK (LEN(Name) > 0)
);

-- 2. Кафедри (Departments)
CREATE TABLE Departments (
    Id INT PRIMARY KEY IDENTITY(1,1),
    Financing MONEY NOT NULL CHECK (Financing >= 0) DEFAULT 0,
    Name NVARCHAR(100) NOT NULL UNIQUE CHECK (LEN(Name) > 0),
    FacultyId INT NOT NULL,
    FOREIGN KEY (FacultyId) REFERENCES Faculties(Id)
);

-- 3. Куратори (Curators)
CREATE TABLE Curators (
    Id INT PRIMARY KEY IDENTITY(1,1),
    Name NVARCHAR(MAX) NOT NULL CHECK (LEN(Name) > 0),
    Surname NVARCHAR(MAX) NOT NULL CHECK (LEN(Surname) > 0)
);

-- 4. Групи (Groups)
CREATE TABLE Groups (
    Id INT PRIMARY KEY IDENTITY(1,1),
    Name NVARCHAR(10) NOT NULL UNIQUE CHECK (LEN(Name) > 0),
    Year INT NOT NULL CHECK (Year BETWEEN 1 AND 5),
    DepartmentId INT NOT NULL,
    FOREIGN KEY (DepartmentId) REFERENCES Departments(Id)
);

-- 5. Групи та куратори (GroupsCurators)
CREATE TABLE GroupsCurators (
    Id INT PRIMARY KEY IDENTITY(1,1),
    CuratorId INT NOT NULL,
    GroupId INT NOT NULL,
    FOREIGN KEY (CuratorId) REFERENCES Curators(Id),
    FOREIGN KEY (GroupId) REFERENCES Groups(Id)
);

-- 6. Дисципліни (Subjects)
CREATE TABLE Subjects (
    Id INT PRIMARY KEY IDENTITY(1,1),
    Name NVARCHAR(100) NOT NULL UNIQUE CHECK (LEN(Name) > 0)
);

-- 7. Викладачі (Teachers)
CREATE TABLE Teachers (
    Id INT PRIMARY KEY IDENTITY(1,1),
    Name NVARCHAR(MAX) NOT NULL CHECK (LEN(Name) > 0),
    Salary MONEY NOT NULL CHECK (Salary > 0),
    Surname NVARCHAR(MAX) NOT NULL CHECK (LEN(Surname) > 0)
);

-- 8. Лекції (Lectures)
CREATE TABLE Lectures (
    Id INT PRIMARY KEY IDENTITY(1,1),
    LectureRoom NVARCHAR(MAX) NOT NULL CHECK (LEN(LectureRoom) > 0),
    SubjectId INT NOT NULL,
    TeacherId INT NOT NULL,
    FOREIGN KEY (SubjectId) REFERENCES Subjects(Id),
    FOREIGN KEY (TeacherId) REFERENCES Teachers(Id)
);

-- 9. Групи та лекції (GroupsLectures)
CREATE TABLE GroupsLectures (
    Id INT PRIMARY KEY IDENTITY(1,1),
    GroupId INT NOT NULL,
    LectureId INT NOT NULL,
    FOREIGN KEY (GroupId) REFERENCES Groups(Id),
    FOREIGN KEY (LectureId) REFERENCES Lectures(Id)
);

-- 10. Дні тижня (Dayofweek)
CREATE TABLE Dayofweek (
    Id INT PRIMARY KEY IDENTITY(1,1),
    Day NVARCHAR(20) NOT NULL CHECK(Day != N'')
);

-- Добавляем данные
INSERT INTO Dayofweek (Day) VALUES
('Monday'), ('Tuesday'), ('Wednesday'), ('Thursday'), ('Friday');

-- Добавляем внешний ключ в таблицу GroupsLectures
ALTER TABLE GroupsLectures
ADD DayofweekId INT FOREIGN KEY REFERENCES Dayofweek(Id);

-- Запросы

-- Количество преподавателей по кафедре 'Software Development'
SELECT COUNT(Teachers.Id) AS TeacherCount
FROM Teachers
JOIN Lectures ON Teachers.Id = Lectures.TeacherId
JOIN Subjects ON Lectures.SubjectId = Subjects.Id
JOIN Departments ON Subjects.Id = Departments.Id
WHERE Departments.Name = 'Software Development';

-- Количество лекций, проведенных преподавателем 'Dave McQueen'
SELECT COUNT(Lectures.Id) AS LectureCount
FROM Lectures
JOIN Teachers ON Lectures.TeacherId = Teachers.Id
WHERE Teachers.Name = 'Dave' AND Teachers.Surname = 'McQueen';

-- Количество лекций в аудитории 'D201'
SELECT COUNT(Lectures.Id) AS LectureCount
FROM Lectures
WHERE Lectures.LectureRoom = 'D201';

-- Количество лекций по аудиториям
SELECT LectureRoom, COUNT(Id) AS LectureCount
FROM Lectures
GROUP BY LectureRoom;

-- Количество групп студентов, чьи преподаватели 'Jack Underhill' провели лекции
SELECT COUNT(DISTINCT Groups.Id) AS StudentCount
FROM GroupsLectures
JOIN Lectures ON GroupsLectures.LectureId = Lectures.Id
JOIN Teachers ON Lectures.TeacherId = Teachers.Id
JOIN Groups ON GroupsLectures.GroupId = Groups.Id
WHERE Teachers.Name = 'Jack' AND Teachers.Surname = 'Underhill';

-- Средняя зарплата преподавателей на факультете 'Computer Science'
SELECT AVG(Teachers.Salary) AS AverageSalary
FROM Teachers
JOIN Lectures ON Teachers.Id = Lectures.TeacherId
JOIN Subjects ON Lectures.SubjectId = Subjects.Id
JOIN Departments ON Subjects.Id = Departments.Id
JOIN Faculties ON Departments.FacultyId = Faculties.Id
WHERE Faculties.Name = 'Computer Science';

-- Минимальное и максимальное количество студентов в группах
SELECT MIN(StudentCount) AS MinStudents, MAX(StudentCount) AS MaxStudents
FROM (
    SELECT COUNT(GroupsCurators.GroupId) AS StudentCount
    FROM GroupsCurators
    GROUP BY GroupsCurators.GroupId
) AS GroupCounts;

-- Среднее финансирование по кафедрам
SELECT AVG(Departments.Financing) AS AverageFinancing
FROM Departments;

-- Количество дисциплин, преподаваемых каждым преподавателем
SELECT Teachers.Name + ' ' + Teachers.Surname AS FullName, COUNT(DISTINCT Subjects.Id) AS SubjectCount
FROM Teachers
JOIN Lectures ON Teachers.Id = Lectures.TeacherId
JOIN Subjects ON Lectures.SubjectId = Subjects.Id
GROUP BY Teachers.Name, Teachers.Surname;

-- Количество лекций по дням недели
SELECT Day.Day AS DayOfWeek, COUNT(L.Id) AS LectureCount
FROM Dayofweek AS Day
JOIN GroupsLectures AS GL ON GL.DayofweekId = Day.Id
JOIN Lectures AS L ON L.Id = GL.LectureId
GROUP BY Day.Day;

-- Количество аудиторий, в которых проходят лекции для разных кафедр
SELECT Lectures.LectureRoom, COUNT(DISTINCT Departments.Id) AS DepartmentCount
FROM Lectures
JOIN Subjects ON Lectures.SubjectId = Subjects.Id
JOIN Departments ON Subjects.Id = Departments.Id
GROUP BY Lectures.LectureRoom;

-- Количество дисциплин на факультетах
SELECT Faculties.Name, COUNT(DISTINCT Subjects.Id) AS SubjectCount
FROM Faculties
JOIN Departments ON Faculties.Id = Departments.FacultyId
JOIN Subjects ON Departments.Id = Subjects.Id
GROUP BY Faculties.Name;

-- Количество лекций по преподавателям и аудиториям
SELECT CONCAT(T.Name,' ',T.Surname) AS Teacher, L.LectureRoom AS Room, COUNT(S.Id) AS LectCount
FROM Teachers AS T
JOIN Lectures AS L ON L.TeacherId = T.Id
JOIN Subjects AS S ON L.SubjectId = S.Id
GROUP BY CONCAT(T.Name,' ',T.Surname), L.LectureRoom;
