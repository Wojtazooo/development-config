# Powershell profile usage

Powershell has $profile file which is being run every time we open command line. You can configure various things using this mechanism.
Idea is to place here scrips improving daily development work.

1. Type $profile to find powershell profile file location.
2. Open and modify this file

Example $profile file:

. C:\workspace\env.ps1

. C:\workspace\Tools.DevelopmentTeams\Team-01\powershell-profile\base-settings.ps1
. C:\workspace\Tools.DevelopmentTeams\Team-01\powershell-profile\gitb.ps1
. C:\workspace\Tools.DevelopmentTeams\Team-01\powershell-profile\gitpr.ps1
. C:\workspace\Tools.DevelopmentTeams\Team-01\powershell-profile\gitmm.ps1

env.ps1 file is where user specific variables are stored, this file has to be created manually.

# Oh my posh

In order to make powershell more appealing oh-my-posh can be used.

1. Download oh-my-posh https://ohmyposh.dev/docs/installation/windows
2. Place theme 'ohMyPosh-aleins.omp.json' in C:\Users\YOURUSERNAME\Documents\PowerShell
