# Flask App API Documentation

Complete API documentation for PC Setup Management System.

## Base URL

```
http://localhost:5000/api
```

## Authentication

Currently, the API does not require authentication. In production, implement API key or OAuth authentication.

---

## 1. PC Information Management

### GET /api/pcinfo

Get PC information by serial number.

**Query Parameters:**
- `serial` (required): PC serial number

**Response:**
```json
{
  "pcname": "20251116M",
  "odj_path": "/srv/odj/20251116M.txt"
}
```

**Error Response:**
```json
{
  "error": "PC not found",
  "serial": "ABC123456"
}
```

---

## 2. Setup Logging

### POST /api/log

Record setup log entry.

**Request Body:**
```json
{
  "serial": "ABC123456",
  "pcname": "20251116M",
  "status": "completed",
  "timestamp": "2025-11-16 12:33:22",
  "logs": "Setup completed successfully"
}
```

**Response:**
```json
{
  "result": "ok"
}
```

---

## 3. PC Master CRUD

### GET /api/pc

List all PCs.

**Query Parameters:**
- `limit` (optional): Number of records to return (default: 100)
- `offset` (optional): Number of records to skip (default: 0)

**Response:**
```json
{
  "success": true,
  "count": 10,
  "pcs": [
    {
      "id": 1,
      "serial": "ABC123456",
      "pcname": "20251116M",
      "odj_path": "/srv/odj/20251116M.txt",
      "created_at": "2025-11-16T12:00:00",
      "updated_at": "2025-11-16T12:00:00"
    }
  ]
}
```

### POST /api/pc

Create new PC record.

**Request Body:**
```json
{
  "serial": "ABC123456",
  "pcname": "20251116M",
  "odj_path": "/srv/odj/20251116M.txt"
}
```

**Response:**
```json
{
  "success": true,
  "message": "PC created successfully",
  "pc": {
    "id": 1,
    "serial": "ABC123456",
    "pcname": "20251116M"
  }
}
```

### PUT /api/pc/<id>

Update PC record.

**Request Body:**
```json
{
  "pcname": "20251117M",
  "odj_path": "/srv/odj/20251117M.txt"
}
```

### DELETE /api/pc/<id>

Delete PC record.

**Response:**
```json
{
  "success": true,
  "message": "PC deleted successfully"
}
```

---

## 4. CSV Import/Export

### POST /api/import/csv

Import PC data from CSV file.

**Request:**
- Content-Type: `multipart/form-data`
- Field: `file` (CSV file)

**CSV Format:**
```csv
serial,pcname,odj_path
ABC123456,20251116M,/srv/odj/20251116M.txt
DEF789012,20251117M,/srv/odj/20251117M.txt
```

**Response:**
```json
{
  "success": true,
  "summary": {
    "total_rows": 100,
    "success_count": 95,
    "error_count": 3,
    "duplicate_count": 2
  },
  "imported_records": [...],
  "errors": [...],
  "duplicates": [...]
}
```

### GET /api/export/csv

Export all PC data to CSV.

**Response:**
- Content-Type: `text/csv`
- CSV file download

---

## 5. ODJ File Management

### POST /api/odj/upload

Upload ODJ file.

**Request:**
- Content-Type: `multipart/form-data`
- Field: `file` (ODJ file)
- Field: `pcname` (optional): PC name to associate
- Field: `serial` (optional): Serial number to associate

**Response:**
```json
{
  "success": true,
  "message": "ODJ file uploaded successfully",
  "file": {
    "filename": "20251116M.txt",
    "path": "/srv/odj/20251116M.txt",
    "size": 4096
  },
  "pc_updated": {
    "id": 1,
    "serial": "ABC123456",
    "pcname": "20251116M"
  }
}
```

### GET /api/odj/list

List all ODJ files.

**Response:**
```json
{
  "success": true,
  "count": 10,
  "files": [
    {
      "filename": "20251116M.txt",
      "path": "/srv/odj/20251116M.txt",
      "size": 4096,
      "created_at": 1700123456.0,
      "modified_at": 1700123456.0,
      "associated_pc": {
        "id": 1,
        "serial": "ABC123456",
        "pcname": "20251116M"
      }
    }
  ]
}
```

### POST /api/odj/associate

Associate ODJ file with PC.

**Request Body:**
```json
{
  "odj_path": "/srv/odj/20251116M.txt",
  "serial": "ABC123456"
}
```

**Response:**
```json
{
  "success": true,
  "message": "ODJ file associated successfully",
  "pc": {...}
}
```

### DELETE /api/odj/delete/<filename>

Delete ODJ file.

**Response:**
```json
{
  "success": true,
  "message": "ODJ file deleted successfully",
  "filename": "20251116M.txt",
  "removed_associations": 1
}
```

---

## 6. Master Image Management

### GET /api/images

List all Clonezilla master images.

**Response:**
```json
{
  "success": true,
  "count": 5,
  "images": [
    {
      "name": "windows11-master-20251116",
      "path": "/home/partimag/windows11-master-20251116",
      "size": 25000000000,
      "size_gb": 23.28,
      "created_at": 1700123456.0,
      "modified_at": 1700123456.0,
      "partitions": ["sda1", "sda2"],
      "disk": "sda",
      "has_metadata": true
    }
  ],
  "image_directory": "/home/partimag/"
}
```

### GET /api/images/<image_name>

Get detailed information about a specific image.

**Response:**
```json
{
  "success": true,
  "image": {
    "name": "windows11-master-20251116",
    "path": "/home/partimag/windows11-master-20251116",
    "size": 25000000000,
    "size_gb": 23.28,
    "partitions": ["sda1", "sda2"],
    "disk": "sda",
    "filesystems": "...",
    "metadata": "...",
    "files": [
      {
        "name": "disk",
        "size": 4,
        "size_mb": 0.0
      }
    ],
    "file_count": 15
  }
}
```

### POST /api/images

Register a new master image.

**Request Body:**
```json
{
  "name": "windows11-master-20251116",
  "description": "Windows 11 with Office 365",
  "created_by": "admin"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Image registered successfully",
  "image": {...}
}
```

### DELETE /api/images/<image_name>

Delete a master image.

**Response:**
```json
{
  "success": true,
  "message": "Image deleted successfully",
  "image_name": "windows11-master-20251116",
  "size_freed_gb": 23.28
}
```

---

## 7. Deployment Management

### POST /api/deployment

Create a new deployment.

**Request Body:**
```json
{
  "name": "Deployment 2025-11-16 Batch 1",
  "image_name": "windows11-master-20251116",
  "mode": "multicast",
  "target_serials": ["ABC123456", "DEF789012"],
  "created_by": "admin",
  "notes": "Deploy to 20 PCs in Room A"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Deployment created successfully",
  "deployment": {
    "id": 1,
    "name": "Deployment 2025-11-16 Batch 1",
    "image_name": "windows11-master-20251116",
    "mode": "multicast",
    "status": "pending",
    "target_count": 2
  }
}
```

### GET /api/deployment

List all deployments.

**Query Parameters:**
- `status` (optional): Filter by status
- `limit` (optional): Number of records to return (default: 50)

**Response:**
```json
{
  "success": true,
  "count": 10,
  "deployments": [...]
}
```

### GET /api/deployment/active

Get all active deployments.

**Response:**
```json
{
  "success": true,
  "count": 2,
  "deployments": [...]
}
```

### GET /api/deployment/<id>

Get deployment details.

**Response:**
```json
{
  "success": true,
  "deployment": {
    "id": 1,
    "name": "Deployment 2025-11-16 Batch 1",
    "status": "running",
    "progress": 45,
    "target_pcs": [...]
  }
}
```

### GET /api/deployment/<id>/status

Get real-time deployment status.

**Response:**
```json
{
  "success": true,
  "status": {
    "deployment_id": 1,
    "status": "running",
    "progress": 45,
    "started_at": "2025-11-16T12:00:00",
    "elapsed_seconds": 1200
  }
}
```

### POST /api/deployment/<id>/start

Start a deployment.

**Response:**
```json
{
  "success": true,
  "message": "Deployment started successfully",
  "deployment": {...}
}
```

### POST /api/deployment/<id>/stop

Stop a running deployment.

**Response:**
```json
{
  "success": true,
  "message": "Deployment stopped",
  "deployment": {...}
}
```

### PUT /api/deployment/<id>

Update deployment configuration.

**Request Body:**
```json
{
  "name": "Updated Deployment Name",
  "notes": "Updated notes",
  "status": "completed",
  "progress": 100
}
```

### DELETE /api/deployment/<id>

Delete a deployment.

**Response:**
```json
{
  "success": true,
  "message": "Deployment deleted successfully"
}
```

---

## Error Responses

All API endpoints use standard HTTP status codes and return error responses in the following format:

```json
{
  "error": "Error message",
  "details": "Additional error details (optional)",
  "field": "Field name that caused error (optional)"
}
```

### HTTP Status Codes

- `200 OK`: Request successful
- `201 Created`: Resource created successfully
- `400 Bad Request`: Invalid request data
- `404 Not Found`: Resource not found
- `500 Internal Server Error`: Server error

---

## Rate Limiting

Currently, no rate limiting is implemented. In production, implement rate limiting to prevent abuse.

## CORS

CORS is configurable via environment variables. Set `CORS_ENABLED=true` and `CORS_ORIGINS` in `.env` file.

## File Size Limits

- CSV Import: 100MB max
- ODJ Files: 10MB max

## Testing

Use curl or Postman to test API endpoints:

```bash
# Get PC info
curl "http://localhost:5000/api/pcinfo?serial=ABC123456"

# Create PC
curl -X POST http://localhost:5000/api/pc \
  -H "Content-Type: application/json" \
  -d '{"serial":"ABC123456","pcname":"20251116M"}'

# Upload CSV
curl -X POST http://localhost:5000/api/import/csv \
  -F "file=@pcs.csv"

# List images
curl http://localhost:5000/api/images
```
