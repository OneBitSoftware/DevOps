
# Install MongoDB (https://www.mongodb.com/docs/manual/tutorial/install-mongodb-on-ubuntu)

# 1) Import the public key used by the package management system
sudo apt-get install gnupg curl

curl -fsSL https://pgp.mongodb.com/server-7.0.asc | \
   sudo gpg -o /usr/share/keyrings/mongodb-server-7.0.gpg \
   --dearmor

# 2) Create a list file for MongoDB
echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-7.0.gpg ] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/7.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-7.0.list

# 3) Reload local package database
sudo apt-get update

# 4) Install the MongoDb packages (USE Latest v5.xx.xx)
sudo apt-get install -y mongodb-org=7.0.3 mongodb-org-database=7.0.3 mongodb-org-server=7.0.3 mongodb-mongosh=7.0.3 mongodb-org-mongos=7.0.3 mongodb-org-tools=7.0.3

# 5) Lock mongo package versions
echo "mongodb-org hold" | sudo dpkg --set-selections
echo "mongodb-org-database hold" | sudo dpkg --set-selections
echo "mongodb-org-server hold" | sudo dpkg --set-selections
echo "mongodb-mongosh hold" | sudo dpkg --set-selections
echo "mongodb-org-mongos hold" | sudo dpkg --set-selections
echo "mongodb-org-tools hold" | sudo dpkg --set-selections

# Run MongoDB 