// Deployment Management JavaScript

document.addEventListener('DOMContentLoaded', function() {
    initializeDeploymentForm();
});

function initializeDeploymentForm() {
    const imageSelect = document.getElementById('imageSelect');
    const deploymentForm = document.getElementById('deploymentForm');
    const pcCheckboxes = document.querySelectorAll('.pc-checkbox');
    const selectAllPCs = document.getElementById('selectAllPCs');
    const pcSearchInput = document.getElementById('pcSearchInput');

    if (!deploymentForm) return;

    // Load images
    loadImages();

    // Image selection handler
    if (imageSelect) {
        imageSelect.addEventListener('change', function() {
            const imageName = this.value;
            document.getElementById('summaryImage').textContent = imageName || '未選択';
        });
    }

    // Mode selection handler
    document.querySelectorAll('input[name="deploymentMode"]').forEach(radio => {
        radio.addEventListener('change', function() {
            const mode = this.value === 'multicast' ? 'マルチキャスト' : 'ユニキャスト';
            document.getElementById('summaryMode').textContent = mode;
        });
    });

    // PC checkbox handlers
    if (pcCheckboxes) {
        pcCheckboxes.forEach(checkbox => {
            checkbox.addEventListener('change', updateSelectedPCs);
        });
    }

    // Select all handler
    if (selectAllPCs) {
        selectAllPCs.addEventListener('change', function() {
            const visibleCheckboxes = document.querySelectorAll('.pc-item:not(.d-none) .pc-checkbox');
            visibleCheckboxes.forEach(checkbox => {
                checkbox.checked = this.checked;
            });
            updateSelectedPCs();
        });
    }

    // PC search
    if (pcSearchInput) {
        pcSearchInput.addEventListener('input', function() {
            const searchTerm = this.value.toLowerCase();
            document.querySelectorAll('.pc-item').forEach(item => {
                const pcname = item.dataset.pcname || '';
                const serial = item.dataset.serial || '';
                if (pcname.includes(searchTerm) || serial.includes(searchTerm)) {
                    item.classList.remove('d-none');
                } else {
                    item.classList.add('d-none');
                }
            });
        });
    }

    // Form submission
    if (deploymentForm) {
        deploymentForm.addEventListener('submit', function(e) {
            e.preventDefault();

            const image = imageSelect.value;
            const mode = document.querySelector('input[name="deploymentMode"]:checked').value;
            const selectedPCs = Array.from(document.querySelectorAll('.pc-checkbox:checked'))
                .map(cb => ({
                    id: cb.value,
                    serial: cb.dataset.serial,
                    pcname: cb.dataset.pcname
                }));

            if (!image) {
                alert('マスターイメージを選択してください');
                return;
            }

            if (selectedPCs.length === 0) {
                alert('対象PCを選択してください');
                return;
            }

            if (!confirm(`${selectedPCs.length}台のPCへの展開を開始しますか？`)) {
                return;
            }

            startDeployment(image, mode, selectedPCs);
        });
    }
}

function loadImages() {
    const imageSelect = document.getElementById('imageSelect');
    if (!imageSelect) return;

    fetch('/api/images')
        .then(response => response.json())
        .then(data => {
            imageSelect.innerHTML = '<option value="">-- イメージを選択 --</option>';
            if (data.images && data.images.length > 0) {
                data.images.forEach(image => {
                    const option = document.createElement('option');
                    option.value = image.name;
                    option.textContent = image.name;
                    imageSelect.appendChild(option);
                });
            }
        })
        .catch(error => {
            console.error('Error loading images:', error);
        });
}

function updateSelectedPCs() {
    const count = document.querySelectorAll('.pc-checkbox:checked').length;
    const selectedCount = document.getElementById('selectedCount');

    if (selectedCount) {
        selectedCount.textContent = `${count}台選択`;
    }

    const pcList = Array.from(document.querySelectorAll('.pc-checkbox:checked'))
        .map(cb => cb.dataset.pcname)
        .slice(0, 5)
        .join(', ');

    const summaryPCs = document.getElementById('summaryPCs');
    if (summaryPCs) {
        if (count > 0) {
            const moreText = count > 5 ? ` 他${count - 5}台` : '';
            summaryPCs.innerHTML = `${count}台<br><small class="text-muted">${pcList}${moreText}</small>`;
        } else {
            summaryPCs.textContent = '0台';
        }
    }
}

function startDeployment(image, mode, selectedPCs) {
    const btn = document.getElementById('startDeploymentBtn');
    if (!btn) return;

    btn.disabled = true;
    btn.innerHTML = '<span class="spinner-border spinner-border-sm me-2"></span>展開開始中...';

    const data = {
        image: image,
        mode: mode,
        target_pcs: selectedPCs.map(pc => pc.id),
        target_serials: selectedPCs.map(pc => pc.serial).join(',')
    };

    fetch('/api/deployment/start', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
        },
        body: JSON.stringify(data)
    })
    .then(response => response.json())
    .then(data => {
        if (data.error) {
            alert('エラー: ' + data.error);
            btn.disabled = false;
            btn.innerHTML = '<i class="bi bi-play-circle-fill me-2"></i>展開を開始';
            return;
        }

        if (window.showToast) {
            window.showToast('展開を開始しました', 'success');
        }

        setTimeout(() => {
            window.location.href = '/deployment-status';
        }, 1500);
    })
    .catch(error => {
        console.error('Error:', error);
        alert('展開の開始に失敗しました');
        btn.disabled = false;
        btn.innerHTML = '<i class="bi bi-play-circle-fill me-2"></i>展開を開始';
    });
}
