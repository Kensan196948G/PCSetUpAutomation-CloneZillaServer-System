// PC Setup Automation - Main JavaScript

document.addEventListener('DOMContentLoaded', function() {
    console.log('PC Setup Automation v1.0.0 initialized');

    // Initialize Bootstrap components
    initializeBootstrapComponents();

    // Auto-dismiss alerts after 5 seconds
    autoDispatchAlerts();

    // Form validation
    initializeFormValidation();

    // PC name format validation (YYYYMMDDM)
    initializePCNameValidation();

    // Table row click handler
    initializeTableRowClickHandlers();

    // Confirmation dialogs
    initializeConfirmationDialogs();

    // Initialize tooltips
    initializeTooltips();

    // Add fade-in animation to cards
    addFadeInAnimations();
});

/**
 * Initialize Bootstrap components
 */
function initializeBootstrapComponents() {
    // Initialize popovers
    const popoverTriggerList = [].slice.call(document.querySelectorAll('[data-bs-toggle="popover"]'));
    popoverTriggerList.map(function (popoverTriggerEl) {
        return new bootstrap.Popover(popoverTriggerEl);
    });

    // Initialize tooltips
    const tooltipTriggerList = [].slice.call(document.querySelectorAll('[data-bs-toggle="tooltip"]'));
    tooltipTriggerList.map(function (tooltipTriggerEl) {
        return new bootstrap.Tooltip(tooltipTriggerEl);
    });
}

/**
 * Auto-dismiss alerts after 5 seconds
 */
function autoDispatchAlerts() {
    const alerts = document.querySelectorAll('.alert:not(.alert-permanent)');
    alerts.forEach(function(alert) {
        setTimeout(function() {
            const bsAlert = new bootstrap.Alert(alert);
            bsAlert.close();
        }, 5000);
    });
}

/**
 * Initialize form validation
 */
function initializeFormValidation() {
    const forms = document.querySelectorAll('.needs-validation');
    forms.forEach(function(form) {
        form.addEventListener('submit', function(event) {
            if (!form.checkValidity()) {
                event.preventDefault();
                event.stopPropagation();
            }
            form.classList.add('was-validated');
        }, false);
    });
}

/**
 * PC name format validation (YYYYMMDDM)
 */
function initializePCNameValidation() {
    const pcnameInput = document.getElementById('pcname');
    if (pcnameInput) {
        pcnameInput.addEventListener('input', function() {
            const pattern = /^\d{8}M$/;
            if (!pattern.test(this.value) && this.value.length > 0) {
                this.setCustomValidity('PC名はYYYYMMDDM形式で入力してください（例: 20251116M）');
            } else {
                this.setCustomValidity('');
            }
        });
    }
}

/**
 * Initialize table row click handlers
 */
function initializeTableRowClickHandlers() {
    const tableRows = document.querySelectorAll('table tbody tr[data-href]');
    tableRows.forEach(function(row) {
        row.addEventListener('click', function() {
            window.location.href = this.dataset.href;
        });
        row.style.cursor = 'pointer';
    });
}

/**
 * Initialize confirmation dialogs
 */
function initializeConfirmationDialogs() {
    const confirmButtons = document.querySelectorAll('[data-confirm]');
    confirmButtons.forEach(function(button) {
        button.addEventListener('click', function(event) {
            const message = this.dataset.confirm || '本当に実行しますか？';
            if (!confirm(message)) {
                event.preventDefault();
            }
        });
    });
}

/**
 * Initialize tooltips
 */
function initializeTooltips() {
    const tooltipTriggerList = [].slice.call(document.querySelectorAll('[data-bs-toggle="tooltip"]'));
    tooltipTriggerList.map(function (tooltipTriggerEl) {
        return new bootstrap.Tooltip(tooltipTriggerEl);
    });
}

/**
 * Add fade-in animations to cards
 */
function addFadeInAnimations() {
    const cards = document.querySelectorAll('.card');
    cards.forEach((card, index) => {
        setTimeout(() => {
            card.classList.add('fade-in');
        }, index * 50);
    });
}

/**
 * AJAX form submission helper
 */
window.submitAjaxForm = function(formId, successCallback, errorCallback) {
    const form = document.getElementById(formId);
    if (!form) return;

    form.addEventListener('submit', function(event) {
        event.preventDefault();

        const formData = new FormData(form);
        const url = form.action;
        const method = form.method;

        fetch(url, {
            method: method,
            body: formData
        })
        .then(response => {
            if (!response.ok) {
                throw new Error('Network response was not ok');
            }
            return response.json();
        })
        .then(data => {
            if (successCallback) {
                successCallback(data);
            }
            showToast('処理が完了しました', 'success');
        })
        .catch(error => {
            console.error('Error:', error);
            if (errorCallback) {
                errorCallback(error);
            }
            showToast('エラーが発生しました', 'danger');
        });
    });
};

/**
 * Toast notification helper
 */
window.showToast = function(message, type = 'info') {
    const toast = document.createElement('div');
    toast.className = `alert alert-${type} alert-dismissible fade show position-fixed top-0 end-0 m-3`;
    toast.style.zIndex = '9999';
    toast.style.minWidth = '300px';

    // Icon mapping
    const icons = {
        'success': 'bi-check-circle-fill',
        'danger': 'bi-exclamation-triangle-fill',
        'warning': 'bi-exclamation-circle-fill',
        'info': 'bi-info-circle-fill'
    };

    const icon = icons[type] || icons.info;

    toast.innerHTML = `
        <i class="bi ${icon} me-2"></i>${message}
        <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
    `;
    document.body.appendChild(toast);

    setTimeout(function() {
        const bsAlert = new bootstrap.Alert(toast);
        bsAlert.close();
    }, 3000);
};

/**
 * Loading spinner helper
 */
window.showLoading = function(elementId) {
    const element = document.getElementById(elementId);
    if (!element) return;

    element.innerHTML = `
        <div class="text-center py-5">
            <div class="spinner-border text-primary" role="status">
                <span class="visually-hidden">読み込み中...</span>
            </div>
            <p class="mt-3 text-muted">読み込み中...</p>
        </div>
    `;
};

/**
 * Format file size
 */
window.formatFileSize = function(bytes) {
    if (bytes === 0) return '0 Bytes';
    const k = 1024;
    const sizes = ['Bytes', 'KB', 'MB', 'GB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    return Math.round(bytes / Math.pow(k, i) * 100) / 100 + ' ' + sizes[i];
};

/**
 * Format date/time
 */
window.formatDateTime = function(dateString) {
    const date = new Date(dateString);
    const year = date.getFullYear();
    const month = String(date.getMonth() + 1).padStart(2, '0');
    const day = String(date.getDate()).padStart(2, '0');
    const hours = String(date.getHours()).padStart(2, '0');
    const minutes = String(date.getMinutes()).padStart(2, '0');
    return `${year}-${month}-${day} ${hours}:${minutes}`;
};

/**
 * Debounce function for search inputs
 */
window.debounce = function(func, wait) {
    let timeout;
    return function executedFunction(...args) {
        const later = () => {
            clearTimeout(timeout);
            func(...args);
        };
        clearTimeout(timeout);
        timeout = setTimeout(later, wait);
    };
};
