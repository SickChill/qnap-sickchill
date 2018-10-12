# QSickChill

SickChill server for QNAP NAS.

SickChill server is automatically pulled from git repository when the package is installed. The repository used is https://github.com/SickChill/SickChill/.

# Install

- Install Git and Python (use the community Python version from http://apps.qnap.community/)
- You can download the latest QPKG packages here https://github.com/SickChill/qnap-sickchill/releases.

# Contribute

- First you need to install the QDK package to your QNAP NAS. You can download it here http://wiki.qnap.com/wiki/QPKG_Development_Guidelines.

- Then clone this repository to into your NAS (use SSH access).

- Go to the folder, make your changes.

- When you're done you can build the package by executing `qbuild`.

- The package is created under `build/` directory.

- Install it by the AppCenter or via the command line `bash build/QSickChill_*.qpkg`.

# Authors

- clinton-hall
- hadim
- miigotu

# License

GPLv3, see [LICENSE](LICENSE).
