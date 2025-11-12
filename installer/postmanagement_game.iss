[Setup]
AppName=Post Management Game
AppVersion=0.1.0
DefaultDirName={autopf64}\\PostManagementGame
DefaultGroupName=Post Management Game
UninstallDisplayIcon={app}\\PostManagementGame.exe
Compression=lzma2
SolidCompression=yes
OutputDir=..
OutputBaseFilename=PostManagementGameSetup
ArchitecturesAllowed=x64
ArchitecturesInstallIn64BitMode=x64
DisableDirPage=no
DisableProgramGroupPage=no

[Languages]
Name: "german"; MessagesFile: "compiler:Languages\\German.isl"
Name: "english"; MessagesFile: "compiler:Default.isl"

[Files]
Source: "build\\windows\\PostManagementGame.exe"; DestDir: "{app}"; Flags: ignoreversion
Source: "build\\windows\\PostManagementGame.pck"; DestDir: "{app}"; Flags: ignoreversion
Source: "build\\windows\\default_env.tres"; DestDir: "{app}"; Flags: ignoreversion onlyifdoesntexist

[Icons]
Name: "{autoprograms}\\Post Management Game"; Filename: "{app}\\PostManagementGame.exe"; WorkingDir: "{app}"
Name: "{autodesktop}\\Post Management Game"; Filename: "{app}\\PostManagementGame.exe"; Tasks: desktopicon

[Tasks]
Name: "desktopicon"; Description: "Desktop-Verknüpfung erstellen"; GroupDescription: "Zusätzliche Aufgaben:"; Flags: unchecked

[Run]
Filename: "{app}\\PostManagementGame.exe"; Description: "Spiel starten"; Flags: nowait postinstall skipifsilent
