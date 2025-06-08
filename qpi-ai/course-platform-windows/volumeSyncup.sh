# Stop the container
docker stop qpi-ai-course

# Install tools (if not already installed)
# sudo apt install -y qemu-utils ntfs-3g

# Connect the disk image
sudo modprobe nbd max_part=16
sudo qemu-nbd --connect=/dev/nbd0 ./windows-data/data.img
sleep 3

# Create mount point
sudo mkdir -p /mnt/windows-disk

# Mount the Windows partition (partition 3)
sudo mount -t ntfs-3g /dev/nbd0p3 /mnt/windows-disk

# Check if it worked
if [ $? -eq 0 ]; then
    echo "✅ Successfully mounted!"
    
    # Look for your folder
    if sudo test -d "/mnt/windows-disk/Users/student/qpi-course-workspace-win"; then
        echo "✅ Found folder: qpi-course-workspace-win!"
        sudo ls -la /mnt/windows-disk/Users/student/qpi-course-workspace-win/
        
        # Copy your files
        sudo cp -r /mnt/windows-disk/Users/student/qpi-course-workspace-win ./
        sudo chown -R $USER:$USER ./qpi-course-workspace-win
        
        echo "✅ Files copied to ./qpi-course-workspace-win/"
        ls -la ./qpi-course-workspace-win/
    else
        echo "Looking for student profile..."
        sudo ls -la /mnt/windows-disk/Users/student/ 2>/dev/null || echo "Student profile not found"
    fi
else
    echo "❌ Mount failed"
fi

# When done, cleanup with:
# sudo umount /mnt/windows-disk
# sudo qemu-nbd --disconnect /dev/nbd0
# docker start qpi-ai-course