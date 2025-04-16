USE hospital_data;

SELECT * 
FROM Patients;

SELECT *
FROM Appointments;

SELECT *
FROM Billing;

SELECT * 
FROM Treatments;

SELECT *
FROM Doctors;

-- 1. CREATING THE AGE COLUMN IN PATIENTS TABEL
		-- Step 1: Add the Age column
ALTER TABLE Patients
ADD COLUMN Age INT;

		-- Step 2: Update the Age column based on Date of Birth (DOB)
UPDATE Patients
SET Age = TIMESTAMPDIFF(YEAR, DOB, CURDATE());

-- MAKING THE COLUMN OF SHIFT THAT PATIENT APPOINTMENTS

ALTER TABLE appointments
ADD COLUMN Shift VARCHAR(200);

UPDATE appointments
SET Shift = CASE 
				WHEN TIME BETWEEN '8:00:00' AND '10:59:59' THEN 'Morning'
                WHEN TIME BETWEEN '11:00:00' AND '15:59:59' THEN 'Afternoon'
                WHEN TIME BETWEEN '16:00:00' AND '17:59:59' THEN 'Evening'
                ELSE 'Not_Assinged'
		     END;

-- CHECKING THE APPOINTMENT OF PARTICULAR PATIENTS FOR WHICH DOCTOR

SELECT 
    P.Name, 
    P.Gender, 
    P.Age, 
    A.Date, 
    A.Time, 
    D.DoctorId,
    D.Name,
    D.Specialty
FROM patients AS P
JOIN appointments AS A ON P.PatientID = A.PatientID
JOIN Doctors AS D ON D.DoctorId = A.DoctorID;

-- HOW MANY PATIENT FOR A PARTICULAR DOCTOR

SELECT 
	D.Name,
	A.DoctorId,
    COUNT(A.PatientId) AS CNT_PATIENTS
FROM appointments AS A
JOIN doctors AS D 
ON A.DoctorID = D.DoctorID
GROUP BY A.DoctorId, D.Name
ORDER BY D.DoctorID ASC;



-- CHECKING THE NO OF PATIENT PER HOUR

SELECT 
	A.Time,
    COUNT(P.PatientID) AS CNT_PATIENTS
FROM patients AS P
JOIN appointments AS A
ON P.PatientID = A.PatientID
WHERE A.Time BETWEEN '9:00:00' AND '12:00:00'
GROUP BY A.Time
ORDER BY CNT_PATIENTS;

-- CHCEKING THE NO. OF PATIENT IN THE PARTICULAR SHIFT

SELECT 
	A.Shift,
    COUNT(P.PatientID) AS CNT_PATIENTS
FROM patients AS P 
JOIN appointments AS A
ON P.PatientID = A.PatientID
GROUP BY Shift
ORDER BY CNT_PATIENTS DESC;

-- CHECKING WHICH SPECILIST HAVE HOW MANY PATIENTS

SELECT 
    D.Specialty, 
    COUNT(P.PatientID) AS CNT_PATIENTS
FROM patients AS P
JOIN appointments AS A ON P.PatientID = A.PatientID
JOIN Doctors AS D ON D.DoctorId = A.DoctorID
GROUP BY D.Specialty
ORDER BY CNT_PATIENTS;

-- CHECKING WHICH SPECILIST HAVE MOST PATIENTS IN WHICH SHIFT

SELECT 
    T.Specialty, 
    COUNT(T.PatientID) AS CNT_PATIENT
FROM (
    SELECT 
        P.PatientID, 
        D.Specialty, 
        A.Shift
    FROM patients AS P
    JOIN appointments AS A ON P.PatientID = A.PatientID
    JOIN Doctors AS D ON D.DoctorId = A.DoctorID
    GROUP BY D.Specialty, A.Shift, P.PatientID  -- Group by Specialty, Shift, and PatientID
) AS T
GROUP BY T.Specialty  -- Group by Specialty from the subquery result
ORDER BY CNT_PATIENT DESC  -- Sort by the count of patients in descending order
;

-- FINDING THE DEMOGRAPHIC 

SELECT 
	Gender,
    CASE 
		WHEN Age < '18' THEN 'UNDER EIGTHTEEN'
        WHEN AGE BETWEEN '18' AND '34' THEN '18-32'
        WHEN Age BETWEEN '34' AND '54' THEN '32-54'
	END Age_Group,
    COUNT(*) AS CNT
FROM patients
GROUP BY Gender,Age_Group
ORDER BY CNT ASC;

-- NO OF MALE AND FEMALE FOR PARTICULAR DOCTOR --

SELECT
	P.Gender,
	COUNT(*) AS Gender_Count
FROM appointments AS A
JOIN doctors AS D
ON A.DoctorID = D.DoctorID
JOIN patients AS P
ON P.PatientID = A.PatientID
GROUP BY P.Gender
ORDER BY Gender_Count;

-- Treatment Outcomes by Specialty

SELECT 
	D.Specialty,
    D.Name,
	T.Outcome,
    COUNT(*) AS Count_Outcome
FROM doctors AS D 
JOIN treatments AS T
ON T.DoctorID = D.DoctorID
GROUP BY D.Specialty,
		D.Name,
		T.Outcome
ORDER BY Count_Outcome ASC;

-- Treatment Current Outcome

SELECT 
	Outcome,
    COUNT(*) AS No_of_Patient_Outcome
FROM treatments
GROUP BY Outcome
ORDER BY No_of_Patient_Outcome;

-- BILLING ANALYSIS OF PARTICULAR DOCTOR

SELECT 
	D.DoctorID,
    D.Name,
    SUM(B.Amount) AS Total_Bill_Amount,
    B.Status,
ROW_NUMBER() OVER(ORDER BY  SUM(B.Amount) DESC) AS TOP_EARNER
FROM appointments AS A
JOIN doctors AS D
ON D.DoctorID = A.DoctorID
JOIN patients AS P
ON A.PatientID = P.PatientID
JOIN billing AS B
ON B.PatientID = A.PatientID
GROUP BY D.DoctorID, D.Name, B.Status; 

-- BILLING ANALYSIS OF PARTICULAR PATIENT --

SELECT 
	P.PatientID,
    P.Name,
    B.amount,
    B.Status
FROM patients AS P
JOIN billing AS B
ON P.PatientID = B.PatientID;

-- BILLING ANALYSIS BY STATUS OF AMOUNTS --

SELECT 
	Status,
	SUM(Amount) AS Total_Amount
FROM billing
GROUP BY Status
ORDER BY Total_Amount DESC;
    
-- BILLING AYNALYSIS FOR THE PENDING DATA --

SELECT *
	FROM(SELECT 
			D.DoctorID,
			D.Name,
			SUM(B.Amount) AS Total_Bill_Amount,
			B.Status
		FROM appointments AS A
		JOIN doctors AS D
		ON D.DoctorID = A.DoctorID
		JOIN patients AS P
		ON A.PatientID = P.PatientID
		JOIN billing AS B
		ON B.PatientID = A.PatientID
		GROUP BY D.DoctorID,D.Name,B.Status) AS T
WHERE Status = 'Pending';     

-- BILLING AYNALYSIS FOR THE PAID DATA --

SELECT *
	FROM(SELECT 
			D.DoctorID,
			D.Name,
			SUM(B.Amount) AS Total_Bill_Amount,
			B.Status
		FROM appointments AS A
		JOIN doctors AS D
		ON D.DoctorID = A.DoctorID
		JOIN patients AS P
		ON A.PatientID = P.PatientID
		JOIN billing AS B
		ON B.PatientID = A.PatientID
		GROUP BY D.DoctorID,D.Name,B.Status) AS T
WHERE Status = 'Paid'; 

-- BILLING STATUS ASSOCIATED TO PATIETS THAT ARE PENDING

SELECT *
	FROM 
		(SELECT 
			P.PatientID,
			P.Name,
			B.amount,
			B.Status
		FROM patients AS P
		JOIN billing AS B
		ON P.PatientID = B.PatientID) AS Patient_Amount
	WHERE Status = 'Pending'
    ORDER BY B.amount;
    
-- MONTHLY BILLING AMOUNT --

SELECT 
    DATE_FORMAT(Date, '%Y %M') AS BillingMonth,
    Status,
    SUM(Amount) AS TotalAmount
FROM 
    Billing
GROUP BY 
    BillingMonth, Status
ORDER BY 
    BillingMonth, Status;

-- AVERAGE BILLING AMOUNT ON THE PARTICULAR TREATMENT --

SELECT
	T.TreatmentType,
	SUM(B.Amount) AS Average_Cost_of_Treatment,
ROW_NUMBER() OVER() AS Most_Common_Treatment
FROM billing AS B
JOIN treatments AS T
ON B.PatientID = T.PatientID
GROUP BY T.TreatmentType
ORDER BY Most_Common_Treatment;
    
-- FINDING PARTICULAR PATIENT HISTORY --

SELECT 
    p.Name,
    t.TreatmentType,
    t.Date,
    t.Outcome
FROM 
    Treatments t
JOIN 
    Patients p ON t.PatientID = p.PatientID
WHERE 
    p.PatientID = 1  -- Replace with the specific PatientID
ORDER BY 
    t.Date;

-- 

