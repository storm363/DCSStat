using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Forms;
using System.IO;
using System.Text.RegularExpressions;
using System.Diagnostics;
using MySql.Data.MySqlClient;

namespace DCSStat
{
    public partial class Form1 : Form
    {
        string temp = null, nickname= "nick", statuscon="offline", ipserver=null, colorplayers="gray";
        bool land = true;
        int crush = 0,eject=0,sec=0,min=0,chas=0, dbCounter = 0;
        int tlen = 1;

        //стринги для бд
        private MySqlConnection connection;
        private string server;
        private string database;
        private string uid;
        private string password;

        public Form1()
        {
            InitializeComponent();
        }

        //метод для обновления базы данных
        private void dbUpdate()
        {
            server = "94.249.139.6";
            database = "dcssta_dcs";
            uid = "dcssta_dcs";
            password = "P@ssw0rd";
            string connectionString;
            connectionString = "SERVER=" + server + ";" + "DATABASE=" + database + ";" + "UID=" + uid + ";" + "PASSWORD=" + password + ";";
            connection = new MySqlConnection(connectionString);
            try
            {
                connection.Open();
                if (connection.State.Equals(ConnectionState.Closed))
                {
                    MessageBox.Show("Succesfully connected!");
                }
                
            }
            catch (MySqlException ex)
            {
                MessageBox.Show(ex.ToString());
            }
        }

        private void timer1_Tick(object sender, EventArgs e)
        {
            //Если процесс есть, идем дальше, если нет, пишем что процесса нет, ждем..
            Process[] pname = Process.GetProcessesByName("DCS");
            if (pname.Length != 0)
            {
                File.Copy(Environment.ExpandEnvironmentVariables(@"%UserProfile%\Saved Games\DCS.openbeta\Logs\dcs.log"), Environment.ExpandEnvironmentVariables(@"%UserProfile%\Saved Games\DCS.openbeta\Logs\dcss.ds"), true);
                StreamReader sr = new StreamReader(Environment.ExpandEnvironmentVariables(@"%UserProfile%\Saved Games\DCS.openbeta\Logs\dcss.ds"));
                string[] a = sr.ReadToEnd().Split('\n');
                for (int i = tlen - 1; i < a.Length - 1; i++)
                {
                    listBox1.Items.Add(i.ToString() + "    " + a[i]);
                    Regex r = new Regex(".*name=");
                    Regex r1 = new Regex(".*IPservera:");
                    Regex r3 = new Regex(".*motd=");
                    if (a[i].Contains("IPservera:"))
                    {
                        ipserver = r1.Replace(a[i].Replace("\"", ""), "");
                        label3.Text = ipserver;
                    }
                    else if (a[i].Contains("connected to server"))
                    {
                        statuscon = "Online";
                        label2.Text = "Online"; label2.ForeColor = Color.Green;
                    }
                    else if (a[i].Contains("PlayerStop"))
                    {
                        statuscon = "Offline";
                        label2.Text = "Offline";
                        label2.ForeColor = Color.Red;
                        land = true;
                    }
                    else if (a[i].Contains("ParametrServ: motd="))
                    {
                        label6.Text = (r3.Replace(a[i].Replace("\"", ""), "")).Trim();

                    }
                    else if (a[i].Contains("DCSStat_name="))
                    {
                        nickname = (r.Replace(a[i].Replace("\"", ""), "")).Trim();
                        label1.Text = nickname;
                    }
                    else if (a[i].Contains("playerfly"))
                    {
                        land = false;
                    }
                    else if (a[i].Contains("playerground"))
                    {
                        land = true;
                    }

                    else if (a[i].Contains("DCSStat_crush"))
                    {
                        Regex r2 = new Regex(".*игрок");
                        if (nickname == (r2.Replace(a[i].Replace("\"", ""), "")).Trim())
                        {
                            crush++;
                            label5.Text = crush.ToString();
                            timer2.Stop();
                            land = true;
                        }
                    }
                    else if (a[i].Contains("DCSStat_info=\"" + nickname))
                    {
                        Regex r4 = new Regex(".*DCSStat_plane=");


                        label7.Text = (r4.Replace(a[i].Replace("\"", ""), "")).Trim();

                    }
                    else if (a[i].Contains("DCSStat_eject"))
                    {
                        Regex r5 = new Regex(".*игрок");
                        if (nickname == (r5.Replace(a[i].Replace("\"", ""), "")).Trim())
                        {
                            eject++;
                            labeject.Text = eject.ToString();
                            land = true;
                        }
                    }
                    else if (a[i].Contains(nickname + "\" took off"))
                    {
                        land = false;
                    }
                    else if (a[i].Contains(nickname + "\" landed"))
                    {
                        land = true;
                        timer2.Stop();
                    }
                    else if (a[i].Contains("КРАСНЫЙ игрок \"" + nickname.Trim() + "\""))
                    {
                        colorplayers = "RED";
                        label4.Text = colorplayers;
                        label4.ForeColor = Color.Red;
                    }
                    else if (a[i].Contains("СИНИЙ игрок \"" + nickname.Trim() + "\""))
                    {
                        colorplayers = "BLUE";
                        label4.Text = colorplayers;
                        label4.ForeColor = Color.Blue;
                    }
                }
                if (land == false)
                    timer2.Start();
                else
                    timer2.Stop();
                sr.Close();
                tlen = a.Length;
                //добавляем у счктчику 10 мс, когда будет 5000, обновляем базу данных
                dbCounter += 10;
                label17.Text = dbCounter.ToString();
                if (dbCounter == 5000)
                {
                    //dbUpdate();
                    dbCounter = 0;
                }
            }
            else
            {
                label2.ForeColor = Color.Red;   
                label2.Text = "DCS is not started!";
            }
        }

        private void Form1_Load(object sender, EventArgs e)
        {
        }

        private void timer2_Tick(object sender, EventArgs e)
        {
            string seco = null,mino=null,chaso=null;
            sec++;
            if (sec >= 60)
            {
                min++;
                sec = 0;
            }
            if(min>=60)
            {
                chas++;
                min = 0;
            }
            if (sec < 10)
                seco = "0";
            else
                seco = "";


            if (min < 10)
                mino = "0";
            else
                mino = "";

            if (chas < 10)
                chaso = "0";
            else
                chaso = "";

            label8.Text = string.Format("Время в полёте {0}{1}:{2}{3}:{4}{5}",chaso, chas,mino, min,seco, sec);

        }

        private void label6_Click(object sender, EventArgs e)
        {

        }
    }
}
