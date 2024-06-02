# Update package list and install Go for windows subsystem for linux
sudo apt update
wget https://dl.google.com/go/go1.21.3.linux-amd64.tar.gz
sudo tar -xvf go1.21.3.linux-amd64.tar.gz
sudo mv go /usr/local
echo "export GOROOT=/usr/local/go" >> ~/.zshrc
echo "export GOPATH=\$HOME/go" >> ~/.zshrc
echo "export PATH=\$GOPATH/bin:\$GOROOT/bin:\$PATH" >> ~/.zshrc
source ~/.zshrc

# Install Subfinder
go install -v github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest
