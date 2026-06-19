# Hand Catch Camera Game

Prototype game HTML5/PWA dung camera dien thoai va MediaPipe Hand Landmarker.

## Chay local

Dung mot static server bat ky:

```powershell
.\start-server.ps1
```

Mo tren may tinh:

```text
http://localhost:5173
```

## Test tren dien thoai

Camera tren dien thoai can HTTPS. Co 2 cach nhanh:

1. Deploy thu muc nay len Netlify, Vercel hoac GitHub Pages.
2. Chay `.\start-server.ps1` va dung HTTPS tunnel nhu Cloudflare Tunnel hoac ngrok.

Sau khi mo link HTTPS tren dien thoai, bam `Bat dau`, cap quyen camera, dua ban tay vao khung hinh va hung cac diem roi.

## Ghi chu ky thuat

- Camera: `navigator.mediaDevices.getUserMedia()`
- Nhan dien tay: `@mediapipe/tasks-vision`
- Render game: HTML Canvas
- PWA: `manifest.webmanifest` va `sw.js`
