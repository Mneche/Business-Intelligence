import pymysql as mysql
######## mysql connection
connection = mysql.connect(host="localhost", user="root", passwd="", db="customerdatabase")
curseur = connection.cursor()

######## Selection from the table
curseur.execute('select * from customerdata')

######## Browsing data
for tmp in curseur:
    print(tmp[0], tmp[1], tmp[2], tmp[3], tmp[4], tmp[5], tmp[6])
connection.close()
curseur.close()