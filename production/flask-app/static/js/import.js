// CSV Import JavaScript

let uploadedData = null;

document.addEventListener('DOMContentLoaded', function() {
    initializeImportForm();
});

function initializeImportForm() {
    const dropZone = document.getElementById('dropZone');
    const fileInput = document.getElementById('csvFileInput');
    const fileInfo = document.getElementById('fileInfo');
    const fileName = document.getElementById('fileName');
    const previewArea = document.getElementById('previewArea');
    const importButtonArea = document.getElementById('importButtonArea');
    const importBtn = document.getElementById('importBtn');
    const cancelBtn = document.getElementById('cancelBtn');
    const resultsArea = document.getElementById('resultsArea');

    if (!dropZone) return;

    // Drag & Drop handlers
    dropZone.addEventListener('dragover', function(e) {
        e.preventDefault();
        e.stopPropagation();
        this.style.backgroundColor = '#e3f2fd';
        this.style.borderColor = '#2196F3';
    });

    dropZone.addEventListener('dragleave', function(e) {
        e.preventDefault();
        e.stopPropagation();
        this.style.backgroundColor = '#f8f9fa';
        this.style.borderColor = '#dee2e6';
    });

    dropZone.addEventListener('drop', function(e) {
        e.preventDefault();
        e.stopPropagation();
        this.style.backgroundColor = '#f8f9fa';
        this.style.borderColor = '#dee2e6';

        const files = e.dataTransfer.files;
        if (files.length > 0) {
            handleFile(files[0]);
        }
    });

    dropZone.addEventListener('click', function() {
        fileInput.click();
    });

    if (fileInput) {
        fileInput.addEventListener('change', function() {
            if (this.files.length > 0) {
                handleFile(this.files[0]);
            }
        });
    }

    if (importBtn) {
        importBtn.addEventListener('click', executeImport);
    }

    if (cancelBtn) {
        cancelBtn.addEventListener('click', resetForm);
    }

    function handleFile(file) {
        if (!file.name.endsWith('.csv')) {
            alert('CSVファイルを選択してください');
            return;
        }

        fileName.textContent = file.name;
        fileInfo.classList.remove('d-none');

        // Upload file to server
        const formData = new FormData();
        formData.append('file', file);

        // Show loading
        const loadingDiv = document.createElement('div');
        loadingDiv.id = 'loading';
        loadingDiv.className = 'alert alert-info mt-2';
        loadingDiv.innerHTML = '<i class="bi bi-hourglass-split me-2"></i>ファイルを解析中...';
        fileInfo.appendChild(loadingDiv);

        fetch('/api/import/upload', {
            method: 'POST',
            body: formData
        })
        .then(response => response.json())
        .then(data => {
            const loading = document.getElementById('loading');
            if (loading) loading.remove();

            if (data.error) {
                alert('エラー: ' + data.error);
                return;
            }

            uploadedData = data;
            displayPreview(data);
        })
        .catch(error => {
            const loading = document.getElementById('loading');
            if (loading) loading.remove();
            console.error('Error:', error);
            alert('ファイルのアップロードに失敗しました');
        });
    }

    function displayPreview(data) {
        const previewBody = document.getElementById('previewBody');
        if (!previewBody) return;

        previewBody.innerHTML = '';

        data.preview.forEach((row, index) => {
            const tr = document.createElement('tr');
            tr.innerHTML = `
                <td>${index + 1}</td>
                <td><code>${row.serial || ''}</code></td>
                <td><strong>${row.pcname || ''}</strong></td>
                <td><small class="text-muted">${row.odj_path || '(未設定)'}</small></td>
            `;
            previewBody.appendChild(tr);
        });

        const totalRows = document.getElementById('totalRows');
        if (totalRows) {
            totalRows.textContent = data.total_rows;
        }

        if (previewArea) previewArea.classList.remove('d-none');
        if (importButtonArea) importButtonArea.classList.remove('d-none');
        if (resultsArea) resultsArea.classList.add('d-none');
    }

    function executeImport() {
        if (!uploadedData || !uploadedData.data) {
            alert('インポートするデータがありません');
            return;
        }

        if (!confirm(`${uploadedData.total_rows} 件のデータをインポートします。よろしいですか？`)) {
            return;
        }

        importBtn.disabled = true;
        importBtn.innerHTML = '<span class="spinner-border spinner-border-sm me-2"></span>登録中...';

        fetch('/api/import/execute', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({
                rows: uploadedData.data
            })
        })
        .then(response => response.json())
        .then(data => {
            importBtn.disabled = false;
            importBtn.innerHTML = '<i class="bi bi-database-add me-2"></i>データベースに登録する';

            if (data.error) {
                alert('エラー: ' + data.error);
                return;
            }

            displayResults(data);
        })
        .catch(error => {
            importBtn.disabled = false;
            importBtn.innerHTML = '<i class="bi bi-database-add me-2"></i>データベースに登録する';
            console.error('Error:', error);
            alert('インポート処理に失敗しました');
        });
    }

    function displayResults(data) {
        const successAlert = document.getElementById('successAlert');
        const errorAlert = document.getElementById('errorAlert');
        const errorList = document.getElementById('errorList');
        const errorDetails = document.getElementById('errorDetails');

        if (document.getElementById('successCount')) {
            document.getElementById('successCount').textContent = data.success_count;
        }

        if (successAlert) {
            successAlert.classList.remove('d-none');
        }

        if (data.error_count > 0) {
            if (document.getElementById('errorCount')) {
                document.getElementById('errorCount').textContent = data.error_count;
            }

            if (errorAlert) {
                errorAlert.classList.remove('d-none');
            }

            if (errorDetails) {
                errorDetails.innerHTML = '';
                data.errors.forEach(error => {
                    const li = document.createElement('li');
                    li.textContent = error;
                    errorDetails.appendChild(li);
                });
            }

            if (errorList) {
                errorList.classList.remove('d-none');
            }
        } else {
            if (errorAlert) errorAlert.classList.add('d-none');
            if (errorList) errorList.classList.add('d-none');
        }

        if (resultsArea) {
            resultsArea.classList.remove('d-none');
            resultsArea.scrollIntoView({ behavior: 'smooth' });
        }

        if (importButtonArea) {
            importButtonArea.classList.add('d-none');
        }
    }

    function resetForm() {
        fileInput.value = '';
        fileInfo.classList.add('d-none');
        previewArea.classList.add('d-none');
        importButtonArea.classList.add('d-none');
        resultsArea.classList.add('d-none');
        uploadedData = null;
    }
}
