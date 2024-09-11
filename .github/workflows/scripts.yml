name: Test Shell Scripts

on:
  push:
    branches:
      - main
  pull_request:
    branches:
      - main
  workflow_dispatch:

jobs:
  test-scripts:
    runs-on: ubuntu-latest

    strategy:
      matrix:
        os: [ubuntu-latest, fedora-latest]

    steps:
    - name: Checkout repository
      uses: actions/checkout@v3

    - name: Set up the environment
      run: |
        echo "Setting up environment for ${{ matrix.os }}"

    - name: Install dependencies for Ubuntu
      if: matrix.os == 'ubuntu-latest'
      run: |
        sudo apt-get update
        sudo apt-get install -y bash

    - name: Install dependencies for Fedora
      if: matrix.os == 'fedora-latest'
      run: |
        sudo dnf install -y bash

    - name: Make scripts executable
      run: |
        chmod +x *.sh

    - name: Test scripts on Ubuntu
      if: matrix.os == 'ubuntu-latest'
      run: |
        for script in *.sh; do
          echo "Running $script on Ubuntu"
          ./$script
        done

    - name: Test scripts on Fedora
      if: matrix.os == 'fedora-latest'
      run: |
        for script in *.sh; do
          echo "Running $script on Fedora"
          ./$script
        done
