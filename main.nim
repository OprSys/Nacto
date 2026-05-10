import fs/fsapi as FS

FS.CreateDirectory("/", "home")
FS.CreateDirectory("/", "etc")
FS.CreateFile("/", "readme", FS.FileType.Text)
FS.CreateDirectory("/home", "user")
FS.CreateFile("/home", "file.txt", FS.FileType.Text)

echo "resolve / => ", FS.ResolvePath("/")
echo "resolve /home => ", FS.ResolvePath("/home")
echo "resolve /home/user => ", FS.ResolvePath("/home/user")
echo "resolve /readme => ", FS.ResolvePath("/readme")
echo "resolve /nonexistent => ", FS.ResolvePath("/nonexistent")
echo "resolve /home/file.txt => ", FS.ResolvePath("/home/file.txt")
