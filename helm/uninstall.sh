#!/bin/bash

# Daemon Monitor Backend Helm Chart Uninstallation Script
# This script removes the daemon-monitor-backend application deployment

set -e

# Configuration
RELEASE_NAME="daemon-monitor"
NAMESPACE="daemon-monitor"

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

# Function to check if release exists
check_release_exists() {
    print_status "Checking if release exists..."
    
    if helm list -n "$NAMESPACE" | grep -q "$RELEASE_NAME"; then
        print_status "Release $RELEASE_NAME found in namespace $NAMESPACE"
        return 0
    else
        print_warning "Release $RELEASE_NAME not found in namespace $NAMESPACE"
        return 1
    fi
}

# Function to uninstall the chart
uninstall_chart() {
    print_status "Uninstalling $RELEASE_NAME release..."
    
    helm uninstall "$RELEASE_NAME" --namespace "$NAMESPACE" --wait --timeout 10m
    
    print_success "Release uninstalled successfully"
}

# Function to remove persistent volumes (optional)
remove_persistent_volumes() {
    print_status "Checking for persistent volumes..."
    
    # List PVCs
    pvcs=$(kubectl get pvc --namespace "$NAMESPACE" -o jsonpath='{.items[*].metadata.name}' 2>/dev/null || true)
    
    if [ -n "$pvcs" ]; then
        print_warning "Found persistent volume claims: $pvcs"
        read -p "Do you want to delete these PVCs? This will permanently delete all data! (y/N): " -n 1 -r
        echo
        
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            print_status "Deleting persistent volume claims..."
            kubectl delete pvc --all --namespace "$NAMESPACE"
            print_success "Persistent volume claims deleted"
        else
            print_warning "Persistent volume claims preserved"
        fi
    else
        print_status "No persistent volume claims found"
    fi
}

# Function to remove namespace (optional)
remove_namespace() {
    print_status "Checking namespace status..."
    
    if kubectl get namespace "$NAMESPACE" >/dev/null 2>&1; then
        read -p "Do you want to delete the namespace '$NAMESPACE'? This will remove all resources! (y/N): " -n 1 -r
        echo
        
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            print_status "Deleting namespace: $NAMESPACE"
            kubectl delete namespace "$NAMESPACE"
            print_success "Namespace deleted"
        else
            print_warning "Namespace preserved"
        fi
    else
        print_status "Namespace $NAMESPACE not found"
    fi
}

# Function to cleanup orphaned resources
cleanup_orphaned_resources() {
    print_status "Checking for orphaned resources..."
    
    # Check for orphaned services
    orphaned_services=$(kubectl get services --all-namespaces -l "app.kubernetes.io/instance=$RELEASE_NAME" --no-headers 2>/dev/null || true)
    
    if [ -n "$orphaned_services" ]; then
        print_warning "Found orphaned services:"
        echo "$orphaned_services"
        read -p "Do you want to delete these orphaned services? (y/N): " -n 1 -r
        echo
        
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            print_status "Deleting orphaned services..."
            kubectl delete services --all-namespaces -l "app.kubernetes.io/instance=$RELEASE_NAME"
            print_success "Orphaned services deleted"
        fi
    fi
    
    # Check for orphaned configmaps
    orphaned_configmaps=$(kubectl get configmaps --all-namespaces -l "app.kubernetes.io/instance=$RELEASE_NAME" --no-headers 2>/dev/null || true)
    
    if [ -n "$orphaned_configmaps" ]; then
        print_warning "Found orphaned configmaps:"
        echo "$orphaned_configmaps"
        read -p "Do you want to delete these orphaned configmaps? (y/N): " -n 1 -r
        echo
        
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            print_status "Deleting orphaned configmaps..."
            kubectl delete configmaps --all-namespaces -l "app.kubernetes.io/instance=$RELEASE_NAME"
            print_success "Orphaned configmaps deleted"
        fi
    fi
    
    # Check for orphaned secrets
    orphaned_secrets=$(kubectl get secrets --all-namespaces -l "app.kubernetes.io/instance=$RELEASE_NAME" --no-headers 2>/dev/null || true)
    
    if [ -n "$orphaned_secrets" ]; then
        print_warning "Found orphaned secrets:"
        echo "$orphaned_secrets"
        read -p "Do you want to delete these orphaned secrets? (y/N): " -n 1 -r
        echo
        
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            print_status "Deleting orphaned secrets..."
            kubectl delete secrets --all-namespaces -l "app.kubernetes.io/instance=$RELEASE_NAME"
            print_success "Orphaned secrets deleted"
        fi
    fi
}

# Function to display uninstallation summary
display_summary() {
    print_success "Uninstallation completed!"
    echo
    echo "Summary:"
    echo "  Release: $RELEASE_NAME"
    echo "  Namespace: $NAMESPACE"
    echo
    echo "Note: Some resources may still exist if you chose to preserve them."
    echo "To reinstall: ./install.sh"
}

# Main execution
main() {
    echo "=========================================="
    echo "Daemon Monitor Backend - Helm Uninstallation"
    echo "=========================================="
    echo
    
    check_prerequisites
    
    if check_release_exists; then
        uninstall_chart
        remove_persistent_volumes
        cleanup_orphaned_resources
    else
        print_warning "No release found to uninstall"
    fi
    
    remove_namespace
    display_summary
}

# Run main function
main "$@"
