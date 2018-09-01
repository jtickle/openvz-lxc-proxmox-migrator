This set of scripts are for migrating CentOS6 OpenVZ containers to
LXC on Proxmox 5.  It might work for non-Proxmox LXC as well.

**These are untested on any container other than CentOS6.  They
are also untested under any circumstance other than OpenVZ -> Proxmox5.
You might be able to modify them for other circumstances, and I'd accept
pull requests if you have success.**

I made these because I had 50+ more or less homogenous containers to migrate.
They're not guaranteed or foolproof.  But my project is complete, and I put
the scripts out here in the hopes that they help someone else.

# CYA
If you don't review these scripts and test them out in a safe environment first,
you're a bad sysadmin and you should feel bad.  It should go without saying that
there ain't no warranty here, but read LICENSE-COPYING before doing anything
else and make sure you understand what it says.

# How To Use
The stage1 script just rsyncs the contents of your container to another host.

The stage2 script replaces some files to make it work with LXC and Proxmox,
and then builds a .tar.xz that can be used as a template to make a new
container.

You're going to want to use SSH keys, private key on openvz, public key on proxmox0.  Root to root.

Deploy the `files` directory from this repository somewhere on your proxmox
host.  I used `/root/migrate/files` for the files directory, and `/root/migrate/work`
for the working directory where it messes with your container files.

## Configure the Scripts
In `proxmox-convert-stage1.sh`:
1. `PRIVATE` should be set to your OpenVZ private base directory, usually `/vz/private`
2. `WORKBASE` should be set to the remote user and host and path that you want to
   work inside of on the proxmox host.  I used `/root/migrate/work` and that is
   reflected in the script.

In `proxmox-convert-stage2.sh`:
1. `MIGRATE` should be set to the Proxmox Template Path, usually `/var/lib/vz/template/cache`
   although if you want to put them on remote storage, here is where you can configure that
2. `WORKBASE` should be set to the path that you set in `WORKBASE` in the stage1 script.
   But keep in mind, it's a local path now.
3. `FILES` should be wherever you have deployed the `files` directory from this repository.

## Migrate A Single Container
1. `ssh OPENVZ_HOST`
2. `proxmox-convert-stage1.sh <VEID>  # This may take awhile`
3. `vzctl stop <VEID>`
4. `proxmox-convert-stage1.sh <VEID>  # This should be pretty quick`
5. `ssh PROXMOX_HOST`
6. `proxmox-convert-stage2.sh <VEID>  # This may take awhile`
7. Use the Proxmox web interface, or the CLI, to create a new LXC container
   based off of `<VEID>.tar.xz`.  You may want to look at /etc/vz/conf/<VEID>.conf for the
   old container to get disk, cpu, ram, and network information.  I took the opportunity to
   increase our minimum sizes a bit.
8. If you want to use your old SSH host keys, run this as root inside the new container:
   `rm -f /etc/ssh/*_key /etc/ssh/*_key.pub; cp /root/ssh_keys/* /etc/ssh/`

## Migrate Multiple Containers
1. `ssh OPENVZ_HOST`
2. `for veid in $(vzlist -a | sed -e 's/^ \+//' | cut -d ' ' -f 1 | tail -n +2); do proxmox-convert-stage1.sh $veid; done`
   This will take a very long time, but you don't have to stop any containers to copy over the bulk of the files
3. For each container, plan some downtime, and start at step 3 under "Migrate a Single Container"

## Issues
In some cases, my first 'yum update' after doing the migration changed some of the files that
the stage2 script places in the new container.  You can read through stage2 if you want, but
here is where the files go if you want to use your ansible or puppet or whtever:

* `files/lxc-halt` -> `/etc/init.d/lxc-halt`
* `files/lxc-sysinit.conf` -> `/etc/init/lxc-sysinit.conf`
* `files/power-status-changed.conf` -> `/etc/init/power-status-changed.conf`
* `files/securetty` -> `/etc/securetty`
* `files/tty.conf` -> `/etc/init/tty.conf`

In particular, if you are unable to get the Proxmox Web Console to work, you need to
replace `/etc/securetty` and `/etc/init/tty.conf` and then stop/start the container.  The other
files have to do with supporting clean shutdowns and reboots.

# References

This whole thing is based on a bit of trial and error.  But, I got a lot of good
information from this page:

https://pve.proxmox.com/wiki/Convert_OpenVZ_to_LXC

# Good Luck!
