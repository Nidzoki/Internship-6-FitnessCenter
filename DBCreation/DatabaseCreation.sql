CREATE DATABASE FitnessCenter

-- Country
CREATE TABLE Country (
    ID SERIAL PRIMARY KEY,
    Name VARCHAR(60) UNIQUE NOT NULL,
    Population INT NOT NULL,
    AverageSalary DECIMAL NOT NULL
);

-- Center
CREATE TABLE Center (
    ID SERIAL PRIMARY KEY,
    Name VARCHAR(30) NOT NULL,
    OpeningTime TIME NOT NULL,
    ClosingTime TIME NOT NULL,
    CountryId INT NOT NULL,
    CONSTRAINT FK_Country FOREIGN KEY (CountryId) REFERENCES Country(ID)
);

-- Activity
CREATE TABLE Activity (
    ID SERIAL PRIMARY KEY,
    Name VARCHAR(30) NOT NULL,
    Type VARCHAR(30) NOT NULL CHECK (Type IN ('strength', 'cardio', 'dance', 'yoga', 'rehab')),
    Capacity INT NOT NULL,
    Code VARCHAR(20) UNIQUE NOT NULL,
    Price DECIMAL NOT NULL
);

-- Trainer
CREATE TABLE Trainer (
    ID SERIAL PRIMARY KEY,
    Name VARCHAR(30) NOT NULL,
    Birthday DATE NOT NULL,
    Sex VARCHAR(1) NOT NULL CHECK (Sex IN ('M', 'F', 'U', 'O')),
    CenterId INT NOT NULL,
    CONSTRAINT FK_Center FOREIGN KEY (CenterId) REFERENCES Center(ID)
);

-- Member
CREATE TABLE Member (
    ID SERIAL PRIMARY KEY,
    Name VARCHAR(30) NOT NULL,
    CenterId INT NOT NULL,
    CONSTRAINT FK_Center_Member FOREIGN KEY (CenterId) REFERENCES Center(ID)
);

-- TrainerActivity

CREATE OR REPLACE FUNCTION check_trainer_lead_limit()
RETURNS TRIGGER AS $$
BEGIN
    IF (NEW.TrainerType = 'lead') THEN
        IF (
            SELECT COUNT(*) 
            FROM TrainerActivity 
            WHERE TrainerId = NEW.TrainerId AND TrainerType = 'lead'
        ) >= 2 THEN
            RAISE EXCEPTION 'Trener ne može biti glavni trener na više od 2 aktivnosti.';
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;



CREATE TABLE TrainerActivity (
    TrainerId INT NOT NULL,
    ActivityId INT NOT NULL,
    TrainerType VARCHAR(4) NOT NULL CHECK (TrainerType IN ('lead', 'help')),
    PRIMARY KEY (TrainerId, ActivityId),
    CONSTRAINT FK_Trainer FOREIGN KEY (TrainerId) REFERENCES Trainer(ID),
    CONSTRAINT FK_Activity FOREIGN KEY (ActivityId) REFERENCES Activity(ID)
);

CREATE TRIGGER check_lead_limit_trigger
BEFORE INSERT OR UPDATE ON TrainerActivity
FOR EACH ROW
EXECUTE FUNCTION check_trainer_lead_limit();


-- MemberActivity

CREATE OR REPLACE FUNCTION check_activity_capacity()
RETURNS TRIGGER AS $$
BEGIN
    IF (
        SELECT COUNT(*) 
        FROM MemberActivity 
        WHERE ActivityId = NEW.ActivityId
    ) >= (
        SELECT Capacity 
        FROM Activity 
        WHERE ID = NEW.ActivityId
    ) THEN
        RAISE EXCEPTION 'Kapacitet aktivnosti je popunjen. Nije moguće dodati novog člana.';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


CREATE TABLE MemberActivity (
    MemberId INT NOT NULL,
    ActivityId INT NOT NULL,
    PRIMARY KEY (MemberId, ActivityId),
    CONSTRAINT FK_Member FOREIGN KEY (MemberId) REFERENCES Member(ID),
    CONSTRAINT FK_Activity_Member FOREIGN KEY (ActivityId) REFERENCES Activity(ID)
);

CREATE TRIGGER check_capacity_trigger
BEFORE INSERT OR UPDATE ON MemberActivity
FOR EACH ROW
EXECUTE FUNCTION check_activity_capacity();

-- Schedule

CREATE TABLE Schedule(
    ID SERIAL PRIMARY KEY,
    ActivityId INT NOT NULL,
    Date Date NOT NULL,
    CONSTRAINT FK_Activity FOREIGN KEY (ActivityId) REFERENCES Activity(ID)
);
