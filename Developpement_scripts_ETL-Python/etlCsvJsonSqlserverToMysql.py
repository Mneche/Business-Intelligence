import pyodbc
import petl as etl
import pymysql as mysql

########## Json extraction and maping
tableJ = etl.fromjson('cust_data.json', header=['id','gender','first_name','last_name', 'email','ville'])
tableJ = etl.movefield(tableJ, 'gender', 4)

########## CSV extraction and conversion
tableCSV = etl.fromcsv('week_cust.csv')
tableCSV = etl.convert(tableCSV, 'id', int)

########### Sqlserver connection and extraction
connectionSqlServer=pyodbc.connect("Driver={SQL Server Native Client 11.0};" "Server=81_64_msdn;" "Database=BD4client;" "Trusted_Connection=yes;" "convert_unicode =True;")
cursor = connectionSqlServer.cursor()
cursor.execute('SELECT id, first_name, last_name, email, gender, ville FROM client_DATA')
tableSqlServer = cursor.fetchall()
tableSqlServer =[('id','first_name','last_name', 'email','gender','ville')]+tableSqlServer
cursor.close()
connectionSqlServer.close()

######### Staging area transforming and concatenation
StagingArea = etl.cat(tableCSV, tableJ,tableSqlServer)
StagingArea = etl.convert(StagingArea, 'gender', {'Male': 'M', 'Female': 'F', 'male': 'M', 'female': 'F', None: 'N'})
StagingArea = etl.rename(StagingArea, 'ville', 'city')

######## mysql
connection = mysql.connect(host="localhost", user="root", passwd="", db="customerdatabase")
curseur = connection.cursor()
curseur.execute('SET SQL_MODE=ANSI_QUOTES')
#### load data, assuming table " CustomerData" already exists in the database
etl.appenddb(StagingArea, connection, 'customerdata', schema='customerdatabase', commit='commit')
curseur.close()
connection.close()