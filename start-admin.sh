#!/bin/bash

echo "========================================="
echo "  Kidpedia Admin System Startup"
echo "========================================="
echo

# Check if Node.js is installed
if ! command -v node &> /dev/null; then
    echo "ERROR: Node.js is not installed"
    echo "Please install Node.js from https://nodejs.org/"
    exit 1
fi

echo "Node.js version:"
node --version
echo

# Navigate to backend directory
echo "[1/4] Setting up Backend..."
cd backend

# Check if node_modules exists
if [ ! -d "node_modules" ]; then
    echo "Installing backend dependencies..."
    npm install
    if [ $? -ne 0 ]; then
        echo "ERROR: Failed to install backend dependencies"
        exit 1
    fi
fi

# Check if .env exists
if [ ! -f ".env" ]; then
    echo "Creating .env file from template..."
    cp .env.example .env
    echo "Please edit backend/.env with your settings if needed"
fi

echo
echo "[2/4] Starting Backend API server..."
npm run dev &
BACKEND_PID=$!

# Wait for backend to start
sleep 5

# Navigate to admin-panel directory
cd ../admin-panel

echo
echo "[3/4] Setting up Admin Panel..."

# Check if node_modules exists
if [ ! -d "node_modules" ]; then
    echo "Installing admin panel dependencies..."
    npm install
    if [ $? -ne 0 ]; then
        echo "ERROR: Failed to install admin panel dependencies"
        kill $BACKEND_PID
        exit 1
    fi
fi

echo
echo "[4/4] Starting Admin Panel..."
npm run dev &
FRONTEND_PID=$!

echo
echo "========================================="
echo "  Startup Complete!"
echo "========================================="
echo
echo "Backend API: http://localhost:8080"
echo "Admin Panel: http://localhost:3000"
echo
echo "Login credentials:"
echo "Username: admin"
echo "Password: admin"
echo
echo "Press Ctrl+C to stop all services"
echo

# Wait for both processes
wait $BACKEND_PID $FRONTEND_PID
