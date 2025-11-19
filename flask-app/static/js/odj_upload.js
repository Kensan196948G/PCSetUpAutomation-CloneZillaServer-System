// ODJ Upload JavaScript

let uploadedFiles = [];
let currentPcId = null;

document.addEventListener('DOMContentLoaded', function() {
    initializeODJUpload();
});

function initializeODJUpload() {
    const odjFiles = document.getElementById('odjFiles');
    const uploadBtn = document.getElementById('uploadBtn');
    const uploadResults = document.getElementById('uploadResults');
    const bindModalElement = document.getElementById('odjBindModal');

    if (!odjFiles) return;

    let bindModal = null;
    if (bindModalElement) {
        bindModal = new bootstrap.Modal(bindModalElement);
    }

    // Enable upload button when files are selected
    odjFiles.addEventListener('change', function() {
        if (uploadBtn) {
            uploadBtn.disabled = this.files.length === 0;
        }
    });

    // Upload files
    if (uploadBtn) {
        uploadBtn.addEventListener('click', function() {
            const files = odjFiles.files;
            if (files.length === 0) return;

            const formData = new FormData();
            for (let i = 0; i < files.length; i++) {
                formData.append('files[]', files[i]);
            }

            uploadBtn.disabled = true;
            uploadBtn.innerHTML = '<span class="spinner-border spinner-border-sm me-2"></span>アップロード中...';

            fetch('/api/odj/upload', {
                method: 'POST',
                body: formData
            })
            .then(response => response.json())
            .then(data => {
                uploadBtn.disabled = false;
                uploadBtn.innerHTML = '<i class="bi bi-cloud-upload me-2"></i>アップロード';

                if (data.error) {
                    alert('エラー: ' + data.error);
                    return;
                }

                displayUploadResults(data);
                odjFiles.value = ''; // Reset file input
                uploadBtn.disabled = true;
            })
            .catch(error => {
                uploadBtn.disabled = false;
                uploadBtn.innerHTML = '<i class="bi bi-cloud-upload me-2"></i>アップロード';
                console.error('Error:', error);
                alert('アップロードに失敗しました');
            });
        });
    }

    // Bind ODJ buttons
    document.querySelectorAll('.bind-odj-btn').forEach(btn => {
        btn.addEventListener('click', function() {
            currentPcId = this.dataset.pcId;
            const pcName = this.dataset.pcName;

            if (document.getElementById('bindPcName')) {
                document.getElementById('bindPcName').textContent = pcName;
            }

            // Populate select with uploaded files
            const select = document.getElementById('odjPathSelect');
            if (select) {
                select.innerHTML = '<option value="">-- 選択してください --</option>';

                uploadedFiles.forEach(file => {
                    const option = document.createElement('option');
                    option.value = file.path;
                    option.textContent = file.filename;
                    select.appendChild(option);
                });
            }

            if (bindModal) {
                bindModal.show();
            }
        });
    });

    // Confirm bind
    const confirmBindBtn = document.getElementById('confirmBindBtn');
    if (confirmBindBtn) {
        confirmBindBtn.addEventListener('click', function() {
            const selectedPath = document.getElementById('odjPathSelect')?.value || '';
            const manualPath = document.getElementById('odjPathManual')?.value?.trim() || '';
            const odjPath = manualPath || selectedPath;

            if (!odjPath) {
                alert('ODJファイルパスを選択または入力してください');
                return;
            }

            this.disabled = true;
            this.innerHTML = '<span class="spinner-border spinner-border-sm me-2"></span>処理中...';

            fetch('/api/odj/bind', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify({
                    pc_id: currentPcId,
                    odj_path: odjPath
                })
            })
            .then(response => response.json())
            .then(data => {
                this.disabled = false;
                this.innerHTML = '<i class="bi bi-link-45deg me-2"></i>紐付ける';

                if (data.error) {
                    alert('エラー: ' + data.error);
                    return;
                }

                if (bindModal) {
                    bindModal.hide();
                }

                if (window.showToast) {
                    window.showToast(data.message, 'success');
                }

                // Reload page after 1 second
                setTimeout(() => {
                    location.reload();
                }, 1000);
            })
            .catch(error => {
                this.disabled = false;
                this.innerHTML = '<i class="bi bi-link-45deg me-2"></i>紐付ける';
                console.error('Error:', error);
                alert('紐付けに失敗しました');
            });
        });
    }

    function displayUploadResults(data) {
        const listDiv = document.getElementById('uploadedFilesList');
        if (!listDiv) return;

        listDiv.innerHTML = '';

        if (data.uploaded_files && data.uploaded_files.length > 0) {
            const successDiv = document.createElement('div');
            successDiv.className = 'alert alert-success';
            successDiv.innerHTML = `
                <i class="bi bi-check-circle-fill me-2"></i>
                <strong>${data.uploaded_files.length}</strong> 個のファイルをアップロードしました
            `;
            listDiv.appendChild(successDiv);

            const ul = document.createElement('ul');
            ul.className = 'mb-0';
            data.uploaded_files.forEach(file => {
                const li = document.createElement('li');
                li.innerHTML = `<code>${file.filename}</code> → <small class="text-muted">${file.path}</small>`;
                ul.appendChild(li);

                // Add to uploaded files array for binding
                uploadedFiles.push(file);
            });
            listDiv.appendChild(ul);
        }

        if (data.errors && data.errors.length > 0) {
            const errorDiv = document.createElement('div');
            errorDiv.className = 'alert alert-warning mt-3';
            errorDiv.innerHTML = `
                <i class="bi bi-exclamation-triangle-fill me-2"></i>
                <strong>${data.errors.length}</strong> 個のエラーがありました
            `;
            listDiv.appendChild(errorDiv);

            const ul = document.createElement('ul');
            ul.className = 'mb-0';
            data.errors.forEach(error => {
                const li = document.createElement('li');
                li.textContent = error;
                ul.appendChild(li);
            });
            listDiv.appendChild(ul);
        }

        if (uploadResults) {
            uploadResults.classList.remove('d-none');
        }
    }
}
