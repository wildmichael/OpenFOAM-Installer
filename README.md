OpenFOAM<sup>&reg;</sup> Installer for Ubuntu
=============================================

This script helps new users to install OpenFOAM on Ubuntu (including Kubuntu,
Xubuntu etc.). Currently, the following versions are supported:

* 10.04 (Lucid Lynx)
* 11.04 (Natty Narwhal)
* 11.10 (Oneiric Ocelot)
* 12.04 LTS (Precise Pangolin)

To use it, open the terminal application (hit `Alt+F2` and type
`gnome-terminal`) and type the following (best by copy-pasting)

    sh <(wget -qO - https://raw.github.com/themiwi/OpenFOAM-Ubuntu-Installer/master/ubuntu-openfoam-installer.sh)

and enter your password when prompted and press `y+Enter` when asked whether
you want to install the openfoam211 and paraviewopenfoam3120 packages and their
dependencies. Do the same when asked if you really want to install
unauthenticated packages.

In order to set up your environment to recognize the OpenFOAM installation,
type the following into the terminal window:

    cp -f --backup=t ~/.bashrc ~/.bashrc.bak
    echo "source /opt/openfoam211/etc/bashrc" >> ~/.bashrc

To finish, close the terminal window and open a new one for the changes to take
effect.

That's it, you're ready to FOAM!

-------------------------------------------------------------------------------

This offering is not  approved  or endorsed by the OpenFOAM<sup>&reg;</sup>
Foundation, the producer of the OpenFOAM software and owner of the OpenFOAM
trademark.
