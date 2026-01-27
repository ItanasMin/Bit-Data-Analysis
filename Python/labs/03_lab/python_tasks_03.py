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


# Task 7: Check whether two dates (2023-03-05 and 2023-03-20) belong 
# to the same month.

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
    print("It's a weekend")
else:
    print("It's a working day")



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


# Task 3: Try to convert the string 'abc' to an integer and handle 
# the ValueError.

try:
    number = int("abc")
    print("Converted number: ", number)
except ValueError:
    print("Error: Cannot convert 'abc' to an integer")


# Task 4: Use try/except/finally – even if there is an error,  
# the finally block must print 'Done'.

try: 
    result = 10 / 0
except ZeroDivisionError:
    print("Error: Division by zero is not allowed.")
finally:
    print("Done")


# Task 5: Create code where two possible errors can occur: division 
# by 0 and invalid conversion.

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


# Task 6: Write a number as a string, then convert it to an integer 
# using try/except.

data_value = "2021"

try:
    number = int(data_value)
    print(f"Conversion successful! The number is: {number}")
except ValueError:
    print("Error: The provided string is not a valid integer.")
finally:
    print("Conversion attempt finished.")


# Task 7: Create a function that raises an error if the input number is
# negative.

input_number = -10

try:
    if input_number < 0:
        raise ValueError("The number cannot be negative!")
    print(f"Success: {input_number} is a valid number.")
except ValueError as e:
    print(f"Caught an error: {e}")
    
    
# Task 8: Use the else block – if no error occurs, print 'Everything is fine' 

try:
    number = 10
    divisor = 2
    result = number / divisor
except ZeroDivisionError:
    print("Error: You cannot divide by zero.")
else:
    print(f"The result is {result}")
    print("Everything is fine")
finally:
    print("Execution finished.")


#  Task 9: Check if the file 'duomenys.txt' exists – if not, notify the user.

try:
    with open("flower_types.csv") as file:
        content = file.read()
        print("File content read successfully.")
except FileNotFoundError:
    print(f"Sorry, we couldn't find '{"flower_types.csv"}'.")


# Task 10: Create a loop with try/except that tries to divide 100 by a list of numbers,
# including zero.

numbers = [10, 20, 0, 50, 5]

for n in numbers:
    try:
        result = 100 / n
        print(f"100 divided by {n} equals {result}")
    except ZeroDivisionError:
        print(f"Skipping {n}: You cannot divide by zero!")
    finally:
        print("--- Calculation step finished ---")
print("The loop has completed its job.")


# Boolean tasks

# Task 1: sentence = "Big data is important for modern analytics"
# Check if the word "data" is present in the "sentence" variable.

sentence = "Big data is important for modern analytics"

result = "data" in sentence
print(result)


# Task 2: Check whether the name 'Asta' is in the list
# names = ['Jonas', 'Asta', 'Tomas']

names = ['Jonas', 'Asta', 'Tomas']

result = 'Asta' in names
print(result)


# Task 3: Check whether the word 'Python' starts with the letter 'P'.

word = "Python"

result = word.startswith('P')
print(result)


# Task 4: Does the word 'analitika' end with the letter 'a'?

word = "analitika"

result = word.endswith('a')
print(result)


# Task 5: Does the sentence 'Python yra naudingas' contain the word 'naudingas'?

sentence = "Python yra naudingas"

result = "naudingas" in sentence
print(result)


# Task 6: Is the number 5 in the list
# numbers = [1, 2, 3, 4, 5, 6]?

numbers = [1, 2, 3, 4, 5, 6]

result = 5 in numbers
print(result)


# Task 7: Is user['logged_in'] True if
# user = {'name': 'Jonas', 'logged_in': True}?

user = {'name': 'Jonas', 'logged_in': True}

result = user['logged_in'] is True
print(result)


# Task 8: Check whether the list
# words = ['duomenys', 'analizė', 'python']
# contains at least one word longer than 7 characters.

words = ['duomenys', 'analizė', 'python']

result = any(len(word) > 7 for word in words)
print(result)


# Task 9: Is x > 10 and x < 20 True if x = 15?

x = 15

result = x > 10 and x < 20
print(result)


# Task 10: Create a variable email = 'jonas@example.com'
# Check whether the email variable contains the character '@'.

email = 'jonas@example.com'

result = '@' in email
print(result)
