# Function Creation Tasks (Data Analytics):

# Task 1: Write a function that takes a number and returns that number multiplied by 2.

def multiple_by_two(number):
    result = number * 2
    return result
my_result = multiple_by_two(18)
print(my_result)


# Task 2: Create a function that returns the conversion rate given the number 
# of users and the number of buyers. Use the formula: (buyers / users) * 100.

def conversion_rate(users, buyers):
    return round((buyers / users) * 100, 2)

rate = conversion_rate(200, 30)
print(rate)


# Task 3: Write a function that calculates CTR (click-through rate): 
# (clicks / impressions) * 100.

def ctr(clicks, impression):
    return round((clicks / impression) * 100, 2)

result = ctr(50, 1000)
print(result)


# Task 4: Create a function that calculates the average value of a 
# given list of numbers. Use sum() and len()

def average(numbers):
    if len(numbers) == 0:
        return 0
    return (sum(numbers)/ len(numbers))

my_numbers = average([2, 5, 18, 546])
print(my_numbers)


# Task 5: Write a function that returns the difference between two numbers – 
# useful for calculating a monthly change.

def difference(a, b):
    return b - a 

last_month = 120
this_month = 250

change = difference(last_month, this_month)
print(change)


# Task 6: Create a function that takes lists of revenue and expenses and returns 
# the net profit for each period (profit − expenses).

def net_profit(revenue, expenses):
    result = []
    for i in range(len(revenue)):
        result.append(revenue[i] - expenses[i])
    return result

revenue = [2500, 2400, 5000]
expenses = [840, 1400, 2800]

result = net_profit(revenue, expenses)
print(result)


# Task 7: Write a function that counts how many times the value 'inactive' appears
# in a given list of user statuses.

def inactive_count(statuses):
    return statuses.count('inactive')

user_statuses = ['active', 'inactive', 'inactive', 'active', 'inactive']
result = inactive_count(user_statuses)
print(f' active clients: {result}')


# Task 8: Write a function that takes a dictionary of sales by region and returns 
# the region with the highest total sales. Use max().

def top_region(sales):
    return max(sales, key=sales.get)

sales = {
    'North': 1500,
    'South': 2700,
    'East': 2200,
    'West': 1800
}

result = top_region(sales)
best_value = sales[result]
print(f'Region with best sales is {result} {best_value}')


# Task 9: 