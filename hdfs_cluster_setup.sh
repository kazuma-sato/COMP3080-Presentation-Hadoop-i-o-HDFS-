#!/bin/bash

# Mapping the nodes 

echo "10.137.160.238 hadoop-master" >> /etc/hosts
echo "10.137.176.107 hadoop-slave-1" >> /etc/hosts
echo "10.137.144.44 hadoop-slave-2" >> /etc/hosts

# Create and Setup SSH Certificates

ssh-keygen -t rsa
ssh-copy-id -i ~/.ssh/id_rsa.pub root@hadoop-master 
ssh-copy-id -i ~/.ssh/id_rsa.pub root@hadoop-slave-1
ssh-copy-id -i ~/.ssh/id_rsa.pub root@hadoop-slave-2 
chmod 0600 ~/.ssh/authorized_keys 
exit

# Install Java
cd ~
apt-get update
apt-get install default-jdk

echo Java version installed
java -version

# Fetch and Install Hadoop
cd ~/Downloads
wget http://mirror.csclub.uwaterloo.ca/apache/hadoop/common/hadoop-2.7.3/hadoop-2.7.3.tar.gz
tar xfz hadoop-2.7.3.tar.gz
mv hadoop-2.7.3 /usr/local/
rm hadoop-2.7.3.tar.gz

# Edit and Setup Configuration Files

# Editing ~/.bashrc

cp /etc/skel/.bash* ~

JAVA_HOME="$(update-alternatives --config java | grep -o -P '(?<=: ).*(?=/jre/bin/java)' )"

echo "#HADOOP VARIABLES START" >> ~/.bashrc
echo "export JAVA_HOME=$JAVA_HOME" >> ~/.bashrc
echo "export HADOOP_INSTALL=/usr/local/hadoop-2.7.3" >> ~/.bashrc
echo "export PATH=\$PATH:\$HADOOP_INSTALL/bin" >> ~/.bashrc
echo "export PATH=\$PATH:\$HADOOP_INSTALL/sbin" >> ~/.bashrc
echo "export HADOOP_MAPRED_HOME=\$HADOOP_INSTALL" >> ~/.bashrc
echo "export HADOOP_COMMON_HOME=\$HADOOP_INSTALL" >> ~/.bashrc
echo "export HADOOP_HDFS_HOME=\$HADOOP_INSTALL" >> ~/.bashrc
echo "export YARN_HOME=\$HADOOP_INSTALL" >> ~/.bashrc
echo "export HADOOP_COMMON_LIB_NATIVE_DIR=\$HADOOP_INSTALL/lib/native" >> ~/.bashrc
echo "export HADOOP_OPTS=\"-Djava.library.path=\$HADOOP_INSTALL/lib\"" >> ~/.bashrc
echo "#HADOOP VARIABLES END" >> ~/.bashrc

sudo . ~/.bashrc

# Editing /usr/local/hadoop-2.7.3/etc/hadoop/hadoop-env.sh
cd $HADOOP_INSTALL/etc/hadoopm
sed -i "/export JAVA_HOME=.*/ c\export JAVA_HOME=$JAVA_HOME" hadoop-env.sh

# Editing /usr/local/hadoop-2.7.3/etc/hadoop/hdfs-site.xml

sed -i '/<property>/,$ d' hdfs-site.xml

echo "<configuration> "                                            >> hdfs-site.xml
echo "   <property> "                                        >> hdfs-site.xml
echo "      <name>dfs.data.dir</name> "                        >> hdfs-site.xml
echo "      <value>/opt/hadoop/dfs/data</value>"			>> hdfs-site.xml
echo "      <final>true</final> "                            >> hdfs-site.xml
echo "   </property> "                                        >> hdfs-site.xml

echo "   <property> "                                        >> hdfs-site.xml
echo "      <name>dfs.name.dir</name> "                     >> hdfs-site.xml
echo "      <value>/opt/hadoop/dfs/name</value> "     >> hdfs-site.xml
echo "      <final>true</final> "                             >> hdfs-site.xml
echo "   </property> "                                         >> hdfs-site.xml

echo "   <property> "                                         >> hdfs-site.xml
echo "      <name>dfs.replication</name> "                     >> hdfs-site.xml
echo "      <value>1</value> "                                 >> hdfs-site.xml
echo "   </property> "                                         >> hdfs-site.xml
echo "</configuration>"                                     >> hdfs-site.xml
cat hdfs-site.xml

# Editing /usr/local/hadoop-2.7.3/etc/hadoop/core-site.xml

sed -i '/<configuration>/,$ d' core-site.xml
echo "<configuration>"                                  >> core-site.xml
echo "    <property>"                                       >> core-site.xml
echo "        <name>fs.default.name</name>"             >> core-site.xml
echo "        <value>hdfs://hadoop-master:9000</value>"    >> core-site.xml
echo "    </property>"                                     >> core-site.xml

echo "    <property>"                                    >> core-site.xml
echo "        <name>dfs.permissions</name> "            >> core-site.xml
echo "        <value>false</value> "                    >> core-site.xml
echo "    </property> "                                    >> core-site.xml
echo "</configuration>"                                   >> core-site.xml
cat core-site.xml

# Creating and Editing /usr/local/hadoop-2.7.3/etc/hadoop/mapred-site.xml

cp mapred-site.xml.template mapred-site.xml
sed -i '/<configuration>/,$ d' mapred-site.xml
echo "<configuration>"                              >> mapred-site.xml
echo "    <property>"                                >> mapred-site.xml
echo "       <name>mapred.job.tracker</name>"        >> mapred-site.xml
echo "       <value>hadoop-master:9001</value>"        >> mapred-site.xml
echo "    </property>"                                >> mapred-site.xml
echo "</configuration>"                               >> mapred-site.xml
cat mapred-site.xml

cd /usr/local

scp -r $HADOOP_INSTALL hadoop-slave-1:$HADOOP_INSTALL
scp -r $HADOOP_INSTALL hadoop-slave-2:$HADOOP_INSTALL

echo "mkdir -p doesnt work all the time so just make the 2 directories listed in hdfs-site.xml"
mkdir -p /opt/hadoop/dfs/data
mkdir /opt/hadoop/dfs/name

hadoop namenode -format

$HADOOP_INSTALL/sbin/start_all.sh
