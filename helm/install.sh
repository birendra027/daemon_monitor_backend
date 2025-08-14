#!/bin/bash

# Daemon Monitor Backend Helm Chart Installation Script
# This script installs the daemon-monitor-backend application using Helm

set -e

# Configuration
CHART_NAME="daemon-monitor-backend"
RELEASE_NAME="daemon-monitor"
NAMESPACE="daemon-monitor"
CHART_PATH="./helm"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    if ! command_exists helm; then
        print_error "Helm is not installed. Please install Helm first."
        exit 1
    fi
    
    if ! command_exists kubectl; then
        print_error "kubectl is not installed. Please install kubectl first."
        exit 1
    fi
    
    # Check if kubectl can connect to cluster
    if ! kubectl cluster-info >/dev/null 2>&1; then
        print_error "Cannot connect to Kubernetes cluster. Please check your kubeconfig."
        exit 1
    fi
    
    print_success "Prerequisites check passed"
}

# Function to create namespace
create_namespace() {
    print_status "Creating namespace: $NAMESPACE"
    
    if kubectl get namespace "$NAMESPACE" >/dev/null 2>&1; then
        print_warning "Namespace $NAMESPACE already exists"
    else
        kubectl create namespace "$NAMESPACE"
        print_success "Namespace $NAMESPACE created"
    fi
}

# Function to add required repositories
add_repositories() {
    print_status "Adding required Helm repositories..."
    
    # Add Bitnami repository for MySQL dependency
    if ! helm repo list | grep -q "bitnami"; then
        helm repo add bitnami https://charts.bitnami.com/bitnami
        print_success "Added Bitnami repository"
    else
        print_warning "Bitnami repository already exists"
    fi
    
    # Update repositories
    helm repo update
    print_success "Repositories updated"
}

# Function to install dependencies
install_dependencies() {
    print_status "Installing chart dependencies..."
    
    cd "$CHART_PATH"
    helm dependency build
    cd - >/dev/null
    
    print_success "Dependencies built"
}

# Function to install the chart
install_chart() {
    print_status "Installing $CHART_NAME chart..."
    
    # Check if release already exists
    if helm list -n "$NAMESPACE" | grep -q "$RELEASE_NAME"; then
        print_warning "Release $RELEASE_NAME already exists. Upgrading..."
        helm upgrade "$RELEASE_NAME" "$CHART_PATH" \
            --namespace "$NAMESPACE" \
            --wait \
            --timeout 10m \
            --set mysql.enabled=true
    else
        helm install "$RELEASE_NAME" "$CHART_PATH" \
            --namespace "$NAMESPACE" \
            --wait \
            --timeout 10m \
            --set mysql.enabled=true
    fi
    
    print_success "Chart installed/upgraded successfully"
}

# Function to verify installation
verify_installation() {
    print_status "Verifying installation..."
    
    # Wait for pods to be ready
    print_status "Waiting for pods to be ready..."
    kubectl wait --for=condition=ready pod -l "app.kubernetes.io/instance=$RELEASE_NAME" \
        --namespace "$NAMESPACE" \
        --timeout=300s
    
    # Check pod status
    print_status "Checking pod status..."
    kubectl get pods --namespace "$NAMESPACE" -l "app.kubernetes.io/instance=$RELEASE_NAME"
    
    # Check services
    print_status "Checking services..."
    kubectl get services --namespace "$NAMESPACE" -l "app.kubernetes.io/instance=$RELEASE_NAME"
    
    print_success "Installation verification completed"
}

# Function to display post-installation information
display_info() {
    print_success "Installation completed successfully!"
    echo
    echo "Release Name: $RELEASE_NAME"
    echo "Namespace: $NAMESPACE"
    echo
    echo "Useful commands:"
    echo "  View pods: kubectl get pods --namespace $NAMESPACE"
    echo "  View services: kubectl get services --namespace $NAMESPACE"
    echo "  View logs: kubectl logs --namespace $NAMESPACE -l app.kubernetes.io/instance=$RELEASE_NAME"
    echo "  Port forward: kubectl port-forward --namespace $NAMESPACE svc/$RELEASE_NAME-app 8080:80"
    echo
    echo "To uninstall: ./uninstall.sh"
}

# Main execution
main() {
    echo "=========================================="
    echo "Daemon Monitor Backend - Helm Installation"
    echo "=========================================="
    echo
    
    check_prerequisites
    create_namespace
    add_repositories
    install_dependencies
    install_chart
    verify_installation
    display_info
}

# Run main function
main "$@"
