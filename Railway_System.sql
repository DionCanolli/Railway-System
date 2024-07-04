-------------------------- Database ----------------------------------------

create database Railway_System;
use Railway_System;

--------------------------- Tables, Stored Procedures, Trigger and View -------------------------

drop table if exists Bookings
drop table if exists Lines_Stations
drop table if exists Trains
drop table if exists Passengers_Children
drop table if exists Passengers_Adults
drop table if exists Passengers
drop table if exists Railway_Stations
drop table if exists Offers
drop table if exists Train_Lines
drop table if exists Cities
drop procedure if exists Create_Adult_Passengers
drop procedure if exists Create_Children_Passengers
drop procedure if exists Book_Adult_Ticket
drop procedure if exists Book_Children_Ticket
drop procedure if exists Find_Lines_Stations_Time_Capacity
drop trigger if exists Decrement_Train_Capacity
drop view if exists Cities_Stations_Lines_View

create table Passengers(
	PassengerID int primary key identity(1,1),
	P_FirstName varchar(25) not null,
	P_LastName varchar(25) not null,
	P_Birthday date not null,
	P_Email varchar(40) not null,
	P_PhoneNumber varchar(12) not null,
	P_Gender bit not null
)


create table Passengers_Adults(
	PassengerID int primary key,
	Profesioni varchar(30) null,
	foreign key (PassengerID) references Passengers(PassengerID)
)

create table Passengers_Children(
	PassengerID int primary key,
	Parent_ID1 int not null,
	Parent_ID2 int null,
	Favorite_Toy varchar(30),
	foreign key(PassengerID) references Passengers(PassengerID),
	foreign key(Parent_ID1) references Passengers_Adults(PassengerID),
	foreign key(Parent_ID2) references Passengers_Adults(PassengerID)
)

create table Cities(
	CityID int primary key identity(1,1),
	CityName varchar(30) not null
)

create table Railway_Stations(
	StationID int primary key identity(1,1),
	Station_Name varchar(50) not null,
	CityID int not null,
	foreign key (CityID) references Cities(CityID)
)

create table Train_Lines(
	Train_Line_ID int primary key identity(1,1), 
	Line_Name varchar(50) not null,
	Departure_Time time not null, 
	Arrival_Time time not null, 
	Original_Price decimal(10,2) not null
)

create table Trains(
	TrainID int primary key identity(1,1),
	Train_Line_ID int not null,
	Capacity int not null,
	Construction_Company varchar(30) not null,
	foreign key(Train_Line_ID) references Train_Lines(Train_Line_ID)
)

create table Lines_Stations(
	Line_Station_ID int primary key identity(1,1),
	Train_Line_ID int not null,
	StationID int not null,
	Row_No int not null,
	foreign key (Train_Line_ID) references Train_Lines(Train_Line_ID),
	foreign key (StationID) references Railway_Stations(StationID)
)

create table Offers(
	OfferID int primary key identity(1,1),
	Offer_Name varchar(25) not null,
	Offer_Start_Date date not null,
	Offer_End_Date date not null,
	Percentage_Of_Discount decimal(10,2) not null
)

create table Bookings(
	BookingID int primary key identity(1,1),
	Train_Line_ID int not null,
	Additional_Services bit not null,
	PassengerID int unique not null,
	Ticket_Price decimal(10,2) not null,
	OfferID int null,
	foreign key (PassengerID) references Passengers(PassengerID),
	foreign key (Train_Line_ID) references Train_Lines(Train_Line_ID),
	foreign key (OfferID) references Offers(OfferID)
)
go

create procedure Create_Adult_Passengers
	@P_FirstName varchar(25),
	@P_LastName varchar(25),
	@P_Birthday date,
	@P_Email varchar(40),
	@P_PhoneNumber varchar(12),
	@P_Gender bit,
	@Profesioni varchar(30) = null
as
begin
	if  @P_Birthday < DATEADD(YEAR, -12, GETDATE())
    	begin
    		insert into Passengers(P_FirstName, P_LastName, P_Birthday, P_Email,
    		P_PhoneNumber, P_Gender) values (@P_FirstName, @P_LastName, @P_Birthday,
    		@P_Email, @P_PhoneNumber,@P_Gender)
    
    		insert into Passengers_Adults(PassengerID, Profesioni)
    		values(SCOPE_IDENTITY(), @Profesioni)
    	end		
    else
		begin	
    		PRINT 'Adult passenger must be +12 years old'; 
		end	  
end
go

create procedure Create_Children_Passengers
	@P_FirstName varchar(25),
	@P_LastName varchar(25),
	@P_Birthday date,
	@P_Email varchar(40),
	@P_PhoneNumber varchar(12),
	@P_Gender bit,
	@Parent_ID1 int,
	@Parent_ID2 int = null,
	@Favorite_Toy varchar(30) = null
as
begin
	begin transaction
		begin try
		begin
			if  @P_Birthday >= DATEADD(YEAR, -12, GETDATE())
    			begin 
    				insert into Passengers(P_FirstName, P_LastName, P_Birthday,
					P_Email,P_PhoneNumber, P_Gender) values (@P_FirstName,
					@P_LastName,	@P_Birthday,@P_Email, @P_PhoneNumber,
					@P_Gender)
    
					insert into Passengers_Children(PassengerID, Parent_ID1,
					Parent_ID2,Favorite_Toy) values(SCOPE_IDENTITY(),
					@Parent_ID1, @Parent_ID2, @Favorite_Toy)
    			end		
			else
				begin	
    				PRINT 'Adult passenger must be younger than 12 years old'; 
				end
		end
		end try
		begin catch
    		PRINT 'There must exist atleast a Parent'; 
			rollback transaction
			return
		end catch
	commit transaction
end
go



create procedure Book_Adult_Ticket
@Train_Line_ID int,
@Additional_Services bit,
@PassengerID int
as
begin
	declare @Capacity_I_Trenit as int = (select Capacity from Trains  
										   where Train_Line_ID = @Train_Line_ID)

	declare @Original_Price as decimal(10,2) = 
						(select Original_Price from Train_Lines
						 where Train_Line_ID = @Train_Line_ID)

	if (@Capacity_I_Trenit > 0)
		begin
			declare @Percentage_Of_Discount as int = 
				(select Percentage_Of_Discount from Offers where 
				 Offer_Start_Date < GETDATE() and 
				 Offer_End_Date > GETDATE())

			declare @OfferID as int = 
				(select OfferID from Offers where 
				 Offer_Start_Date < GETDATE() and 
				 Offer_End_Date > GETDATE())


		    if (@Percentage_Of_Discount is not null)
				begin
					insert into Bookings(Train_Line_ID, Additional_Services,
					PassengerID, Ticket_Price, OfferID) values
					(@Train_Line_ID, @Additional_Services, @PassengerID,
					@Original_Price * @Percentage_Of_Discount / 100, @OfferID)
				end
		    else
				begin
					insert into Bookings(Train_Line_ID, Additional_Services,
					PassengerID, Ticket_Price, OfferID) values
					(@Train_Line_ID, @Additional_Services, @PassengerID,
					@Original_Price, @OfferID)
				end

			
		end
	else
		begin
			print 'There are no free seats on the train.'
		end
end
go

create procedure Book_Children_Ticket
@Childrent_Passenger_ID int,
@Additional_Services bit
as
begin

	declare @Parent_ID1 int = (select pf.Parent_ID1 from Passengers_Children pf
						  inner join Passengers_Adults pr on 
						  pf.Parent_ID1 = pr.PassengerID
						  where pf.PassengerID = @Childrent_Passenger_ID)

	declare @Parent_ID2 int = (select pf.Parent_ID2 from Passengers_Children pf
						  inner join Passengers_Adults pr on 
						  pf.Parent_ID2 = pr.PassengerID
						  where pf.PassengerID = @Childrent_Passenger_ID)	
						  
	declare @Train_Line_ID int = (select Train_Line_ID from Bookings
								where PassengerID = @Parent_ID1)

	declare @OfferID as int = 
			(select OfferID from Offers where 
			 Offer_Start_Date < GETDATE() and 
			 Offer_End_Date > GETDATE())
	
	declare @Percentage_Of_Discount as decimal = 
				(select Percentage_Of_Discount from Offers where 
				 Offer_Start_Date < GETDATE() and 
				 Offer_End_Date > GETDATE())

    if (@Train_Line_ID is null)
		begin
			set @Train_Line_ID = (select Train_Line_ID from Bookings
								where PassengerID = @Parent_ID2)
		end
	
	if	(@Train_Line_ID is not null)
		begin

			declare @Capacity_I_Trenit as int = 
						(select Capacity from 
						Trains where Train_Line_ID = @Train_Line_ID)

			declare @Original_Price as decimal = 
						(select Original_Price from Train_Lines
						 where Train_Line_ID = @Train_Line_ID)

			if (select P_Birthday from Passengers 
			    where PassengerID = @Childrent_Passenger_ID) 
				>= DATEADD(YEAR, -12, GETDATE()) and
				(select P_Birthday from Passengers 
			    where PassengerID = @Childrent_Passenger_ID) 
				< DATEADD(YEAR, -5, GETDATE())
				begin 
					if (@Capacity_I_Trenit > 0)
					    begin
					    	if (@Percentage_Of_Discount is not null)
					    		begin 
					    			insert into Bookings(Train_Line_ID,
					    			Additional_Services,PassengerID, 
					    			Ticket_Price, OfferID) values(@Train_Line_ID,
					    			@Additional_Services, @Childrent_Passenger_ID,
					    			@Original_Price * @Percentage_Of_Discount / 100 *
									50/100, @OfferID)
					    		end
					    	else
					    		begin
					    			insert into Bookings(Train_Line_ID,
					    			Additional_Services, PassengerID,
					    			Ticket_Price, OfferID) values(@Train_Line_ID,
					    			@Additional_Services, @Childrent_Passenger_ID,
					    			@Original_Price * 50/100, @OfferID)
					    		end
						end
					else
						begin
							print 'There are no free seats on the train.'
						end
				end
			if (select P_Birthday from Passengers 
			    where PassengerID = @Childrent_Passenger_ID) 
				>= DATEADD(YEAR, -5, GETDATE()) and
				(select P_Birthday from Passengers 
			    where PassengerID = @Childrent_Passenger_ID) 
				< DATEADD(YEAR, -2, GETDATE())
				begin 
					insert into Bookings(Train_Line_ID, Additional_Services,
					PassengerID, Ticket_Price, OfferID) values
					(@Train_Line_ID, @Additional_Services, @Childrent_Passenger_ID,
					0, @OfferID)
				end
			if (select P_Birthday from Passengers 
			    where PassengerID = @Childrent_Passenger_ID) 
				>= DATEADD(YEAR, -2, GETDATE())
				begin 
					insert into Bookings(Train_Line_ID, Additional_Services,
					PassengerID, Ticket_Price, OfferID) values
					(@Train_Line_ID, @Additional_Services, @Childrent_Passenger_ID,
					0, @OfferID)
				end
		end
	else
		begin
			print 'Neither of his parents have reservations';
		end
end
go


create trigger Decrement_Train_Capacity
on Bookings after insert 
as
begin
	declare @Train_Line_ID int;
	set @Train_Line_ID = (select Train_Line_ID from Bookings
							where BookingID = ident_current('Bookings'));

	declare @Ditelindja date = (select p.P_Birthday from Passengers p
								inner join Bookings r on
								p.PassengerID = r.PassengerID
								where BookingID = ident_current('Bookings'))
	if (@Ditelindja < DATEADD(YEAR, -2, GETDATE()))
	begin
		update Trains set Capacity -= 1
		where Trains.TrainID = (select TrainID from Trains  
		where Train_Line_ID = @Train_Line_ID)
	end
end
go

create procedure Find_Lines_Stations_Time_Capacity
@Train_Line_ID int = null
as 
begin
	if (@Train_Line_ID is not null)
		begin
			select l.Line_Name, s.Station_Name, l.Departure_Time,
				   l.Arrival_Time, t.Capacity
			from Lines_Stations ls inner join Train_Lines l
			on ls.Train_Line_ID = l.Train_Line_ID
			inner join Trains t on
			t.Train_Line_ID = l.Train_Line_ID
			inner join Railway_Stations s on
			ls.StationID = s.StationID
			where l.Train_Line_ID = @Train_Line_ID
		end
	else
		begin
			select l.Line_Name, s.Station_Name, l.Departure_Time,
				   l.Arrival_Time, t.Capacity
			from Lines_Stations ls inner join Train_Lines l
			on ls.Train_Line_ID = l.Train_Line_ID
			inner join Trains t on
			t.Train_Line_ID = l.Train_Line_ID
			inner join Railway_Stations s on
			ls.StationID = s.StationID
		end
end
go

create view Cities_Stations_Lines_View as
select v.CityName, s.Station_Name,l.Line_Name 
from Lines_Stations ls inner join Train_Lines l
on ls.Train_Line_ID = l.Train_Line_ID
inner join Railway_Stations s on
ls.StationID = s.StationID
inner join Cities v
on s.CityID = v.CityID

------------------------------- Data insertion -----------------------------

insert into Cities(CityName) values ('Prishtine'), ('Mitrovice'),
('Gjilan'), ('Gjakove'),('Peja'),('Ferizaj')

insert into Railway_Stations(Station_Name, CityID) values
('S.Prishtina 1', 1), ('S.Prishtina 2', 1), 
('S.Mitrovice 1', 2), ('S.Mitrovice 2', 2), 
('S.Gjilan 1', 3), ('S.Gjilan 2', 3), 
('S.Gjakove 1', 4), ('S.Gjakove 2', 4), 
('S.Peja 1', 5), ('S.Peja 2', 5), 
('S.Ferizaj 1', 6), ('S.Ferizaj 2', 6)

insert into Train_Lines(Line_Name, Departure_Time, Arrival_Time, 
Original_Price) values 
('Prishtine-Gjilan',    '12:10:00', '12:40:00', 1.00),
('Prishtine-Ferizaj',   '08:00:00', '08:50:00', 3.30),
('Gjilan-Prishtine',    '07:40:00', '08:10:00', 2.40),
('Gjilan-Mitrovice',    '08:50:00', '09:50:00', 1.20),
('Gjilan-Peje',         '09:10:00', '10:10:00', 2.10),
('Mitrovice-Gjakove',   '15:50:00', '16:50:00', 2.30),
('Mitrovice-Ferizaj',   '16:20:00', '17:20:00', 3.30),
('Peje-Gjilan',         '17:30:00', '18:30:00', 1.00),
('Gjakove-Ferizaj',     '19:20:00', '19:55:00', 2.50),
('Ferizaj-Gjakove',     '14:20:00', '14:45:00', 3.50),
('Ferizaj-Prishtine',   '11:30:00', '12:00:00', 3.30)

insert into Trains(Train_Line_ID, Capacity, Construction_Company) values
(1, 500, 'AMTRAK'),(2, 2000, 'BNSF'),(3, 600, 'AMTRAK'),
(4, 700, 'NORFOLK'),(5, 400, 'AMTRAK'),(6, 660, 'NORFOLK'),
(7, 550, 'AMTRAK'),(8, 1070, 'BNSF'),(9, 600, 'AMTRAK'),
(10, 670, 'NORFOLK'),(11, 450, 'AMTRAK')

insert into Offers(Offer_Name, Offer_Start_Date, Offer_End_Date, 
Percentage_Of_Discount) values
('Summer offer', '2023-06-11', '2023-08-01', 10.00),
('Spring Offer', '2023-04-01', '2023-05-20', 50.00),
('Winter offer', '2023-12-01', '2024-01-10', 30.00),
('Autumn offer', '2023-09-01', '2023-10-01', 20.00)

insert into Lines_Stations(Train_Line_ID, StationID, Row_No) values
(1,1,1), (1,2,2), (1,5,3), (1,6,4), 
(2,1,1), (2,2,2), (2,11,3), (2,12,4), 
(3,5,1), (3,6,2), (3,1,3), (3,2,4), 
(4,5,1), (4,6,2), (4,3,3), (4,4,4), 
(5,5,1), (5,6,2), (5,9,3), (5,10,4), 
(6,3,1), (6,4,2), (6,7,3), (6,8,4),
(7,3,1), (7,4,2), (7,11,3), (7,12,4),
(8,9,1), (8,10,2), (8,5,3), (8,6,4),
(9,7,1), (9,8,2), (9,11,3), (9,12,4),
(10,11,1), (10,12,2), (10,7,3), (10,8,4),
(11,11,1), (11,12,2), (11,1,3), (11,2,4)


--- 
exec Create_Adult_Passengers
	@P_FirstName = 'Art',
	@P_LastName = 'Gashi',
	@P_Birthday = '2004-12-01',
	@P_Email = 'ag@a.a',
	@P_PhoneNumber = '+123456789',
	@P_Gender = 1,
	@Profesioni = 'Programmer'

exec Create_Adult_Passengers
	@P_FirstName = 'Artan',
	@P_LastName = 'Haxhiu',
	@P_Birthday = '2002-01-01',
	@P_Email = 'd@d.d',
	@P_PhoneNumber = '+123456789',
	@P_Gender = 1,
	@Profesioni = 'Lawyer'

exec Create_Adult_Passengers
	@P_FirstName = 'Fatime',
	@P_LastName = 'Islami',
	@P_Birthday = '2006-01-01',
	@P_Email = 'fi@h.h',
	@P_PhoneNumber = '+123456789',
	@P_Gender = 0,
	@Profesioni = 'Doctor'

exec Create_Adult_Passengers
	@P_FirstName = 'Alba',
	@P_LastName = 'Syla',
	@P_Birthday = '2002-06-05',
	@P_Email = 'a@d.d',
	@P_PhoneNumber = '+123456789',
	@P_Gender = 0,
	@Profesioni = 'Politician'


exec Create_Adult_Passengers
	@P_FirstName = 'Butrint',
	@P_LastName = 'Pllana',
	@P_Birthday = '2002-01-01',
	@P_Email = 'bp@p.p',
	@P_PhoneNumber = '+123456789',
	@P_Gender = 1,
	@Profesioni = 'Chef'

exec Create_Children_Passengers 
	@P_FirstName = 'Bekim',
	@P_LastName = 'Hasani',
	@P_Birthday = '2022-01-01',
	@P_Email = 'b@b.v',
	@P_PhoneNumber = '+123456789',
	@P_Gender = 1,
	@Parent_ID1 = 1,
	@Parent_ID2 = null,
	@Favorite_Toy  = 'Cars'

exec Create_Children_Passengers 
	@P_FirstName = 'Uvejs',
	@P_LastName = 'Shabani',
	@P_Birthday = '2020-01-01',
	@P_Email = 'u@u.sh',
	@P_PhoneNumber = '+123456789',
	@P_Gender = 1,
	@Parent_ID1 = 2,
	@Parent_ID2 = 4,
	@Favorite_Toy  = 'Foot Ball'

exec Create_Children_Passengers 
	@P_FirstName = 'Albion',
	@P_LastName = 'Kuqi',
	@P_Birthday = '2015-01-01',
	@P_Email = 'a@k.k',
	@P_PhoneNumber = '+123456789',
	@P_Gender = 1,
	@Parent_ID1 = 3,
	@Parent_ID2 = 4,
	@Favorite_Toy  = 'Video Games'

exec Create_Children_Passengers 
	@P_FirstName = 'Amir',
	@P_LastName = 'Sadiku',
	@P_Birthday = '2015-01-01',
	@P_Email = 's@s.s',
	@P_PhoneNumber = '+123456789',
	@P_Gender = 1,
	@Parent_ID1 = 5,
	@Favorite_Toy  = 'Cards'

exec Create_Children_Passengers 
	@P_FirstName = 'Orgesa',
	@P_LastName = 'Pireva',
	@P_Birthday = '2013-01-01',
	@P_Email = 'op@po.p',
	@P_PhoneNumber = '+123456789',
	@P_Gender = 1,
	@Parent_ID1 = 1,
	@Favorite_Toy  = 'Barbie'

	
exec Create_Children_Passengers 
	@P_FirstName = 'Hasime',
	@P_LastName = 'Bytyqi',
	@P_Birthday = '2012-01-01',
	@P_Email = 'hb@hb.hb',
	@P_PhoneNumber = '+123456789',
	@P_Gender = 1,
	@Parent_ID1 = 1,
	@Favorite_Toy  = 'UNO'

exec Create_Children_Passengers 
	@P_FirstName = 'Elta',
	@P_LastName = 'Shala',
	@P_Birthday = '2013-01-01',
	@P_Email = 'e@e.e',
	@P_PhoneNumber = '+123456789',
	@P_Gender = 1,
	@Parent_ID1 = 1,
	@Favorite_Toy  = 'Basketball'

	-----------

exec Book_Adult_Ticket 
	 @Train_Line_ID = 1,
	 @Additional_Services = 0,
	 @PassengerID = 1

exec Book_Adult_Ticket 
	 @Train_Line_ID = 1,
	 @Additional_Services = 0,
	 @PassengerID = 2

exec Book_Adult_Ticket 
	 @Train_Line_ID = 3,
	 @Additional_Services = 0,
	 @PassengerID = 3

exec Book_Adult_Ticket 
	 @Train_Line_ID = 2,
	 @Additional_Services = 0,
	 @PassengerID = 4

	 ---

exec Book_Children_Ticket
	@Childrent_Passenger_ID = 6,
	@Additional_Services = 1

exec Book_Children_Ticket
	@Childrent_Passenger_ID = 7,
	@Additional_Services = 1

exec Book_Children_Ticket
	@Childrent_Passenger_ID = 8,
	@Additional_Services = 1

exec Book_Children_Ticket
	@Childrent_Passenger_ID = 9,
	@Additional_Services = 1

exec Book_Children_Ticket
	@Childrent_Passenger_ID = 10,
	@Additional_Services = 1
	
exec Book_Children_Ticket
	@Childrent_Passenger_ID = 11,
	@Additional_Services = 1

exec Book_Children_Ticket
	@Childrent_Passenger_ID = 12,
	@Additional_Services = 1
	---------------

select * from [dbo].[Train_Lines]
select * from [dbo].[Lines_Stations]
select * from [dbo].[Offers]
select * from [dbo].[Passengers]
select * from [dbo].[Passengers_Adults]
select * from [dbo].[Railway_Stations]
select * from [dbo].[Passengers_Children]
select * from [dbo].[Bookings]
select * from [dbo].[Trains]
select * from [dbo].[Cities]
exec Find_Lines_Stations_Time_Capacity @Train_Line_ID = 11
exec Find_Lines_Stations_Time_Capacity
select * from Cities_Stations_Lines_View
go

