
import datetime

# Tasks with Datetime

# Task 1: Create today’s date using datetime.date.today() and print it

today = datetime.date.today()
print(today)


# Task 2: Create the date June 1, 2023 and print it.

date_2023 = datetime.date(2023, 6, 1)
print(date_2023)


# Task 3: Convert the string '2022-12-25' into a datetime object.

date_string = "2022-12-25"
date_object = datetime.datetime.strptime(date_string, "%Y-%m-%d")
print(date_object)


# Task 4: Print which day of the week December 25, 2022 fell on.

date_obj = datetime.date(2022, 12, 25)
print(date_obj.strftime("%A"))


# Task 5: Calculate the number of days between January 1, 2023 and February 1, 2023.

date1 = datetime.date(2023, 1, 1)
date2 = datetime.date(2023, 2, 1)
delta = date2 - date1
print("Number of days:", delta.days)


# Task 6: Create a loop that prints the 1st day of each month in 2023.

for month in range(1, 13):
    first_day = datetime.date(2023, month, 1)
    print(first_day)


# Task 7: Check whether two dates (2023-03-05 and 2023-03-20) belong to the same month.

date_1 = datetime.date(2023, 3, 5)
date_2 = datetime.date(2023, 3, 20)
if date_1.year  == date_2.year and date_1.month == date_2.month:
    print("The dates are in the same month.")
else:
    print("The dates are not in the same month.")


# Task 8: Convert today’s date into a string in the format YYYY-MM-DD.

today_date = datetime.date.today()
date_to_string = today_date.strftime("%Y-%m-%d")
print(today_date)


# Task 9: Create a date from year, month, and day given as variables.

year = 2016
month = 5
day = 14
date_from_variables = datetime.date(year, month, day)
print(date_from_variables)


# Task 10: Check whether a given date falls on a weekend (Saturday or Sunday).

data = datetime.date(2026, 1, 6)
if data.weekday() >= 6:
    print("Tai savaitgalis")
else:
    print("Tai darbo diena")



# Tasks with try/except/finally:


# Task 1: Write code that divides 10 by 0 and handles ZeroDivisionError.

try:
    x = 10 / 0
    print("Result:", x)
except ZeroDivisionError:
    print("Error: Cannot divide by zero!")


# Task 2: Try to open a non-existent file and handle the FileNotFoundError.

try:
    with open("secrent_santa.csv") as f:
        content = f.read()
except FileNotFoundError:
    print("Sorry, the file was not found. Please check the filename.") 


# Task 3: Try to convert the string 'abc' to an integer and handle the ValueError.

try:
    number = int("abc")
    print("Converted number: ", number)
except ValueError:
    print("Error: Cannot convert 'abc' to an integer")


# Task 4: Use try/except/finally – even if there is an error, the finally block must print 'Done'.

try: 
    result = 10 / 0
except ZeroDivisionError:
    print("Error: Division by zero is not allowed.")
finally:
    print("Done")


# Task 5: Create code where two possible errors can occur: division by 0 and invalid conversion.

try: 
    numbers = int("user_input")
    result = 50 / number
    print(f"Success! The result is: {result}")
except ValueError:
    print("Error: Input value must be a number.")
except ZeroDivisionError:
    print("Error: Division by zero is not allowed.")
finally:
    print("Process finished.")


