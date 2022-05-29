
import apt, apt.debfile
import pathlib, stat, shutil, urllib.request, subprocess, getpass, time, tempfile
import secrets, json, re
import IPython.utils.io
import ipywidgets
import socket
import os
from IPython.display import clear_output

class _NoteProgress(apt.progress.base.InstallProgress, apt.progress.base.AcquireProgress, apt.progress.base.OpProgress):
  def __init__(self):
    apt.progress.base.InstallProgress.__init__(self)
    self._label = ipywidgets.Label()
    display(self._label)
    self._float_progress = ipywidgets.FloatProgress(min = 0.0, max = 1.0, layout = {'border':'1px solid #118800'})
    display(self._float_progress)

  def close(self):
    self._float_progress.close()
    self._label.close()

  def fetch(self, item):
    self._label.value = "fetch: " + item.shortdesc

  def pulse(self, owner):
    self._float_progress.value = self.current_items / self.total_items
    return True

  def status_change(self, pkg, percent, status):
    self._label.value = "%s: %s" % (pkg, status)
    self._float_progress.value = percent / 100.0

  def update(self, percent=None):
    self._float_progress.value = self.percent / 100.0
    self._label.value = self.op + ": " + self.subop

  def done(self, item=None):
    pass

class _MyApt:
  def __init__(self):
    self._progress = _NoteProgress()
    self._cache = apt.Cache(self._progress)

  def close(self):
    self._cache.close()
    self._cache = None
    self._progress.close()
    self._progress = None

  def update_upgrade(self):
    self._cache.update()
    self._cache.open(None)
    self._cache.upgrade()

  def commit(self):
    self._cache.commit(self._progress, self._progress)
    self._cache.clear()

  def installPkg(self, *args):
    for name in args:
      pkg = self._cache[name]
      if pkg.is_installed:
        print(f"{name} is already installed")
      else:
        pkg.mark_install()

  def installDebPackage(self, name):
    apt.debfile.DebPackage(name, self._cache).install()

  def deleteInstalledPkg(self, *args):
    for pkg in self._cache:
      if pkg.is_installed:
        for name in args:
          if pkg.name.startswith(name):
            #print(f"Delete {pkg.name}")
            pkg.mark_delete()

def _download(url, path):
  try:
    with urllib.request.urlopen(url) as response:
      with open(path, 'wb') as outfile:
        shutil.copyfileobj(response, outfile)
  except:
    print("Failed to download ", url)
    raise

  return True

def _setupssh():
  #Inpur Username
  print("Create a username :")
  user_name = input()
  subprocess.run(["useradd", "-s", "/bin/bash", "-m", user_name])
  subprocess.run(["adduser", user_name, "sudo"], check = True)
  clear_output()

  #Inpur Password
  print("Create a password :")
  user_password = getpass.getpass()
  subprocess.run(["chpasswd"], input = f"{user_name}:{user_password}", universal_newlines = True)
  clear_output()

  #Set your ngrok Authtoken.
  print("Copy & paste your tunnel authtoken from https://dashboard.ngrok.com/auth")
  print("(You need to sign up for ngrok and login.)")
  ngrok_token = getpass.getpass()
  clear_output()

  #Set your ngrok region.
  print("Select your ngrok region :")
  print("us - United States (Ohio)")
  print("eu - Europe (Frankfurt)")
  print("ap - Asia/Pacific (Singapore)")
  print("au - Australia (Sydney)")
  print("sa - South America (Sao Paulo)")
  print("jp - Japan (Tokyo)")
  print("in - India (Mumbai)")
  ngrok_region = input()
  clear_output()

  #SSH Dropbear
  my_apt = _MyApt()
  my_apt.installPkg("dropbear")
  my_apt.commit()
  my_apt.close()

  #Set Dropbear
  f = open("../etc/default/dropbear", "w")
  f.write("""# the TCP port that Dropbear listens on
DROPBEAR_PORT=443

# any additional arguments for Dropbear
DROPBEAR_EXTRA_ARGS=

# specify an optional banner file containing a message to be
# sent to clients before they connect, such as "/etc/issue.net"
DROPBEAR_BANNER=""

# RSA hostkey file (default: /etc/dropbear/dropbear_rsa_host_key)
#DROPBEAR_RSAKEY="/etc/dropbear/dropbear_rsa_host_key"

# DSS hostkey file (default: /etc/dropbear/dropbear_dss_host_key)
#DROPBEAR_DSSKEY="/etc/dropbear/dropbear_dss_host_key"

# ECDSA hostkey file (default: /etc/dropbear/dropbear_ecdsa_host_key)
#DROPBEAR_ECDSAKEY="/etc/dropbear/dropbear_ecdsa_host_key"

# Receive window size - this is a tradeoff between memory and
# network performance
DROPBEAR_RECEIVE_WINDOW=65536
""")
  f.close()

  #SSH Service Restart
  subprocess.run(["service", "dropbear", "restart"])

  #Root Password
  root_password = user_password
  subprocess.run(["chpasswd"], input = f"root:{root_password}", universal_newlines = True)

  # Ngrok Tunnel
  if not os.path.exists('ngrok.zip'):
    _download("https://bin.equinox.io/a/kpRGfBMYeTx/ngrok-2.2.8-linux-amd64.zip", "ngrok.zip")
    shutil.unpack_archive("ngrok.zip")
    pathlib.Path("ngrok").chmod(stat.S_IXUSR)

  subprocess.run(["./ngrok", "authtoken", ngrok_token])
  ngrok_proc = subprocess.Popen(["./ngrok", "tcp", "-region", ngrok_region, "443"])
  time.sleep(2)

  with urllib.request.urlopen("http://localhost:4040/api/tunnels") as response:
    url = json.load(response)['tunnels'][0]['public_url']
    m = re.match("tcp://(.+):(\d+)", url)

  hostname = m.group(1)
  port = m.group(2)
  
  msg = ""
  msg += "="*48 + "\n"
  msg += ">>>>>>:\n"
  msg += f"ssh -p {port} {user_name}@{socket.gethostbyname(hostname)}\n"
  msg += "="*48 + "\n"
  msg += ">>>>>>>>>>>>:\n"
  msg += f"host          : ssh -p {port} {user_name}@{socket.gethostbyname(hostname)}\n"
  msg += f"Username      : {user_name}\n"
  msg += f"Password      : {user_password}\n"
  msg += "="*48 + "\n"
  return msg

def startColab():
  msg = _setupssh()
  print(msg)

startColab()
