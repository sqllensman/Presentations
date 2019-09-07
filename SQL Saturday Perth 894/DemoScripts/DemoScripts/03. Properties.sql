USE AdventureWorks2016;
GO

-- Execution plans appear to be exactly identical.
-- Why???

SELECT  p.*                 -- For real code, always avoid SELECT * at the outer level!
FROM    Person.Person AS p;

SELECT  p.BusinessEntityID,
        p.FirstName,
        p.MiddleName,
        p.LastName,
        p.ModifiedDate
FROM    Person.Person AS p
WHERE   p.ModifiedDate >= '2013-01-01';
GO
