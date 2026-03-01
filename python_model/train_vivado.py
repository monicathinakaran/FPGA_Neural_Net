import torch
import torch.nn as nn
import torch.optim as optim
from torchvision import datasets, transforms
import numpy as np
import os

class SimpleMLP(nn.Module):
    def __init__(self):
        super(SimpleMLP, self).__init__()
        self.fc1 = nn.Linear(784, 16) 
        self.relu = nn.ReLU()
        self.fc2 = nn.Linear(16, 10)  

    def forward(self, x):
        x = x.view(-1, 784)
        x = self.fc1(x)
        x = self.relu(x)
        x = self.fc2(x)
        return x

# Helper function for Vivado $readmemh (8-bit Two's Complement Hex)
def to_hex_8bit(val):
    return f"{(int(val) & 0xFF):02X}"

def main():
    transform = transforms.Compose([transforms.ToTensor(), transforms.Normalize((0.5,), (0.5,))])
    train_dataset = datasets.MNIST(root='./data', train=True, download=True, transform=transform)
    train_loader = torch.utils.data.DataLoader(train_dataset, batch_size=64, shuffle=True)

    model = SimpleMLP()
    criterion = nn.CrossEntropyLoss()
    optimizer = optim.SGD(model.parameters(), lr=0.01, momentum=0.9)

    print("Training the network...")
    for epoch in range(2): 
        for images, labels in train_loader:
            optimizer.zero_grad()
            output = model(images)
            loss = criterion(output, labels)
            loss.backward()
            optimizer.step()

    print("\nExporting Hex Weights for Vivado...")
    scale_factor = 128.0 # Q7 Format
    
    w1 = np.round(model.fc1.weight.data.numpy() * scale_factor).astype(np.int32)
    
    os.makedirs("weights", exist_ok=True)
    
    # Write to a text file in Vivado hex format
    with open("weights/w1_hex.txt", "w") as f:
        for row in w1:
            for val in row:
                f.write(to_hex_8bit(val) + "\n")
                
    print("Export Complete! Check the 'weights' folder for w1_hex.txt.")

if __name__ == "__main__":
    main()