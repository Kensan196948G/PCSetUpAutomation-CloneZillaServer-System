// Image Management JavaScript

document.addEventListener('DOMContentLoaded', function() {
    initializeImageManagement();
});

function initializeImageManagement() {
    // Load images on page load
    loadImages();

    // Setup upload form if exists
    const uploadForm = document.getElementById('uploadImageForm');
    if (uploadForm) {
        uploadForm.addEventListener('submit', handleImageUpload);
    }

    // Setup delete buttons
    document.addEventListener('click', function(e) {
        if (e.target.classList.contains('delete-image-btn')) {
            const imageName = e.target.dataset.imageName;
            handleImageDelete(imageName);
        }
    });

    // Setup refresh button
    const refreshBtn = document.getElementById('refreshImagesBtn');
    if (refreshBtn) {
        refreshBtn.addEventListener('click', loadImages);
    }
}

function loadImages() {
    const imagesList = document.getElementById('imagesList');
    const imagesCount = document.getElementById('imagesCount');
    const loadingIndicator = document.getElementById('imagesLoading');

    if (!imagesList) return;

    // Show loading
    if (loadingIndicator) {
        loadingIndicator.classList.remove('d-none');
    }

    fetch('/api/images')
        .then(response => response.json())
        .then(data => {
            if (data.error) {
                showError('Failed to load images: ' + data.error);
                return;
            }

            // Update count
            if (imagesCount) {
                imagesCount.textContent = data.count || 0;
            }

            // Clear list
            imagesList.innerHTML = '';

            if (data.images && data.images.length > 0) {
                data.images.forEach((image, index) => {
                    const row = createImageRow(image, index === 0);
                    imagesList.appendChild(row);
                });
            } else {
                imagesList.innerHTML = `
                    <tr>
                        <td colspan="6" class="text-center text-muted py-4">
                            <i class="bi bi-inbox me-2"></i>
                            マスターイメージがありません
                        </td>
                    </tr>
                `;
            }
        })
        .catch(error => {
            console.error('Error loading images:', error);
            showError('Failed to load images: ' + error.message);
        })
        .finally(() => {
            if (loadingIndicator) {
                loadingIndicator.classList.add('d-none');
            }
        });
}

function createImageRow(image, isDefault) {
    const tr = document.createElement('tr');

    const statusBadge = isDefault
        ? '<span class="badge bg-success"><i class="bi bi-check-circle me-1"></i>デフォルト</span>'
        : '<span class="badge bg-secondary"><i class="bi bi-circle me-1"></i>非アクティブ</span>';

    tr.innerHTML = `
        <td>
            <strong class="text-dark">${escapeHtml(image.name)}</strong>
            <br>
            <small class="text-muted">${image.disk_count || 0}個のディスク</small>
        </td>
        <td>
            <code class="text-break small">${escapeHtml(image.path)}</code>
        </td>
        <td>
            <span>${image.size_human || '-'}</span>
        </td>
        <td>
            ${image.created || '-'}
        </td>
        <td>
            ${statusBadge}
        </td>
        <td>
            <div class="btn-group btn-group-sm" role="group">
                <a href="/api/images/${encodeURIComponent(image.name)}"
                   class="btn btn-outline-primary"
                   title="詳細情報を表示"
                   target="_blank">
                    <i class="bi bi-eye"></i>
                </a>
                <button type="button"
                        class="btn btn-outline-danger delete-image-btn"
                        data-image-name="${escapeHtml(image.name)}"
                        title="イメージを削除">
                    <i class="bi bi-trash"></i>
                </button>
            </div>
        </td>
    `;

    return tr;
}

function handleImageUpload(e) {
    e.preventDefault();

    const form = e.target;
    const fileInput = document.getElementById('imageFile');
    const imageNameInput = document.getElementById('imageName');
    const descriptionInput = document.getElementById('imageDescription');
    const submitBtn = form.querySelector('button[type="submit"]');

    if (!fileInput.files || fileInput.files.length === 0) {
        showError('ファイルを選択してください');
        return;
    }

    const file = fileInput.files[0];

    // Validate file type
    if (!file.name.endsWith('.tar.gz') && !file.name.endsWith('.tgz') && !file.name.endsWith('.zip')) {
        showError('サポートされていないファイル形式です。.tar.gz または .zip を使用してください。');
        return;
    }

    // Create form data
    const formData = new FormData();
    formData.append('file', file);

    if (imageNameInput && imageNameInput.value) {
        formData.append('image_name', imageNameInput.value);
    }

    if (descriptionInput && descriptionInput.value) {
        formData.append('description', descriptionInput.value);
    }

    // Disable submit button
    const originalText = submitBtn.innerHTML;
    submitBtn.disabled = true;
    submitBtn.innerHTML = '<span class="spinner-border spinner-border-sm me-2"></span>アップロード中...';

    // Upload
    fetch('/api/images/upload', {
        method: 'POST',
        body: formData
    })
    .then(response => response.json())
    .then(data => {
        if (data.error) {
            showError('アップロードエラー: ' + data.error);
            return;
        }

        showSuccess('イメージをアップロードしました: ' + data.image.name);

        // Reset form
        form.reset();

        // Reload images
        loadImages();

        // Close modal if exists
        const modal = bootstrap.Modal.getInstance(document.getElementById('uploadImageModal'));
        if (modal) {
            modal.hide();
        }
    })
    .catch(error => {
        console.error('Upload error:', error);
        showError('アップロードに失敗しました: ' + error.message);
    })
    .finally(() => {
        submitBtn.disabled = false;
        submitBtn.innerHTML = originalText;
    });
}

function handleImageDelete(imageName) {
    if (!confirm(`イメージ "${imageName}" を削除しますか？\n\nこの操作は取り消せません。`)) {
        return;
    }

    fetch(`/api/images/${encodeURIComponent(imageName)}`, {
        method: 'DELETE'
    })
    .then(response => response.json())
    .then(data => {
        if (data.error) {
            showError('削除エラー: ' + data.error);
            return;
        }

        showSuccess(`イメージを削除しました: ${imageName} (${data.size_freed})`);

        // Reload images
        loadImages();
    })
    .catch(error => {
        console.error('Delete error:', error);
        showError('削除に失敗しました: ' + error.message);
    });
}

function showError(message) {
    if (window.showToast) {
        window.showToast(message, 'error');
    } else {
        alert('エラー: ' + message);
    }
}

function showSuccess(message) {
    if (window.showToast) {
        window.showToast(message, 'success');
    } else {
        alert(message);
    }
}

function escapeHtml(text) {
    const map = {
        '&': '&amp;',
        '<': '&lt;',
        '>': '&gt;',
        '"': '&quot;',
        "'": '&#039;'
    };
    return text.replace(/[&<>"']/g, m => map[m]);
}
