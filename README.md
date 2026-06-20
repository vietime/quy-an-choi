# Quy An Choi

Prototype web/PWA cho nhom ban quan ly quy an choi:

- Tao thanh vien va ma nap rieng cho tung nguoi.
- Ghi nhan khoan nop quy thu cong.
- Mo phong sao ke ngan hang: he thong doc noi dung chuyen khoan, tim ma nap va tu cong tien cho thanh vien.
- Tao buoi an/nhau, chon thanh vien tham gia va tu phan bo bill.
- Gan tien nguoi la/khach moi cho mot nguoi trong nhom.
- Moi thanh vien thay duoc da nop, da dung va so du con lai.
- Lich su giao dich theo dang so cai de truy vet tien vao/tien ra.

## Chay local

```powershell
.\start-server.ps1
```

Mo:

```text
http://localhost:5173
```

Du lieu demo luu trong `localStorage` cua trinh duyet. Bam `Lam moi demo` de reset.

## Nguyen tac tinh tien

So du tung thanh vien:

```text
so du = tong tien da nop - tong chi phi duoc phan bo
```

Khi tao buoi:

- `Chia deu cho nguoi tham gia`: tong bill tru tien khach la, phan con lai chia deu.
- `Nguoi duoc gan tra phan khach la`: bill chia deu cho nguoi tham gia, tien khach la cong them vao nguoi duoc gan.

## De xuat tinh nang cho ban production

- Dang nhap bang so dien thoai, Google hoac OTP.
- Vai tro: admin quy, thu quy, thanh vien chi duoc xem.
- QR nap tien that theo VietQR hoac link vi dien tu, noi dung chuyen khoan bat buoc chua ma thanh vien.
- Webhook ngan hang/vi dien tu de tu nhan giao dich, doi soat so tien va noi dung.
- Hang doi giao dich chua nhan dien de thu quy gan thu cong.
- Anh hoa don, dia diem, ngay gio, nguoi tao buoi.
- Cho phep split nang cao: chia deu, nguoi uong bia tra them, nguoi den muon tra %, mien phi cho khach.
- Trang thai thanh vien: dang tham gia, tam dung, da roi nhom nhung giu lich su.
- Thong bao Zalo/Telegram/Email khi nap quy, bi tru tien, so du am.
- Xuat bao cao Excel/PDF theo thang.
- Khoa so quy theo ky de chot cong no.
- Audit log bat bien: ai sua gi, luc nao, ly do.

## Huong kien truc goi y

- Frontend: React/Vue/Svelte hoac PWA thuan neu app nho.
- Backend: Node.js/NestJS, Laravel hoac Supabase.
- Database: PostgreSQL voi cac bang `funds`, `members`, `ledger_entries`, `events`, `event_participants`, `bank_transactions`.
- Thanh toan/nhan dien: VietQR cho noi dung chuyen khoan, webhook tu ngan hang/doi tac trung gian, job doi soat dinh ky.
- Bao mat: moi phep cong/tru tien phai xu ly o backend, client chi gui yeu cau.
