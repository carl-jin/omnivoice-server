; Inno Setup script for omnivoice-server (Windows).
; Compile with build_windows.ps1, which passes /DMyVersion and /DMyVariant.
;
;   ISCC.exe /DMyVersion=0.2.4 /DMyVariant=cpu packaging\omnivoice-server.iss
;
; Packages the PyInstaller one-dir output (dist\omnivoice-server\) into a
; standard Program Files install with Start Menu + optional desktop shortcut.

#define MyAppName "OmniVoice Server"
#define MyAppPublisher "zamery"
#define MyAppURL "https://github.com/maemreyo/omnivoice-server"
#define MyAppExeName "omnivoice-server.exe"

#ifndef MyVersion
  #define MyVersion "0.0.0"
#endif
#ifndef MyVariant
  #define MyVariant "cpu"
#endif

[Setup]
AppId={{4CAB4194-6E02-4382-A248-46430C00034E}
AppName={#MyAppName}
AppVersion={#MyVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
DefaultDirName={autopf}\OmniVoice Server
DefaultGroupName=OmniVoice Server
DisableProgramGroupPage=yes
; SourceDir defaults to this .iss file's folder (packaging/), so paths are
; relative to packaging/. Emit the installer into the repo-root dist/ to match
; build_windows.ps1 and the CI upload path.
OutputDir=..\dist
OutputBaseFilename=OmniVoice-Server-{#MyVersion}-windows-{#MyVariant}-setup
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
PrivilegesRequired=admin

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
Source: "..\dist\omnivoice-server\*"; DestDir: "{app}"; Flags: recursesubdirs createallsubdirs ignoreversion

[Icons]
Name: "{group}\OmniVoice Server"; Filename: "{app}\{#MyAppExeName}"
Name: "{group}\{cm:UninstallProgram,OmniVoice Server}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\OmniVoice Server"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "Start OmniVoice Server now (first run downloads ~3GB model)"; Flags: nowait postinstall skipifsilent
