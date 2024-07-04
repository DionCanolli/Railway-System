Project Title: Railway System

Description: This is a database designed to maintain a railway system. 

Installation Instructions: All you have to do is download the .sql file, then open it in Microsoft SQL Server Management Studio

Usage: You can directly call scripts from Microsoft SQL Server Management Studio or from any programming language.

Technologies Used: SQL Server

Features: 
	First here are the tables: Bookings, Lines_Stations, Trains, Passengers_Children, Passengers_Adults, Passengers, Railway_Stations, Offers, Train_Lines and Cities.
	These are the procedures: Create_Adult_Passengers, Create_Children_Passengers, Book_Adult_Ticket, Book_Children_Ticket, Find_Lines_Stations_Time_Capacity
	This is the trigger: Decrement_Train_Capacity
	This is the view: Cities_Stations_Lines_View

	Here are some features of the procedures:
		1. Adult Passengers must be older than 12 years old, as for the Children Passengers, they must be 12 years old or younger.
		2. Children Passengers must have atleast a parent.
		3. To book a ticket for adults or children, the train they are taking, must have enough capacity.
		4. For Children whose age is between 12 and 6 (including 12 and 6) they have a 50% discount for ticket price, for those children whose age is between 5 and 3 (including 5 		   and 3) they don't pay for ticket price, and those children whose age is 2 or lower, they don't have to pay and dont need a seat (since they stay with their parent/s).