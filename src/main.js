const STORAGE_KEY = "playFundApp.v1";

const currency = new Intl.NumberFormat("vi-VN", {
  style: "currency",
  currency: "VND",
  maximumFractionDigits: 0,
});

const els = {
  totalFund: document.querySelector("#totalFund"),
  totalSpent: document.querySelector("#totalSpent"),
  memberCount: document.querySelector("#memberCount"),
  pendingCount: document.querySelector("#pendingCount"),
  memberForm: document.querySelector("#memberForm"),
  memberName: document.querySelector("#memberName"),
  memberWallet: document.querySelector("#memberWallet"),
  memberList: document.querySelector("#memberList"),
  depositForm: document.querySelector("#depositForm"),
  depositMember: document.querySelector("#depositMember"),
  depositAmount: document.querySelector("#depositAmount"),
  depositNote: document.querySelector("#depositNote"),
  bankForm: document.querySelector("#bankForm"),
  bankContent: document.querySelector("#bankContent"),
  bankAmount: document.querySelector("#bankAmount"),
  qrBoard: document.querySelector("#qrBoard"),
  eventForm: document.querySelector("#eventForm"),
  eventName: document.querySelector("#eventName"),
  eventAmount: document.querySelector("#eventAmount"),
  guestAmount: document.querySelector("#guestAmount"),
  guestOwner: document.querySelector("#guestOwner"),
  splitMode: document.querySelector("#splitMode"),
  participantList: document.querySelector("#participantList"),
  eventPreview: document.querySelector("#eventPreview"),
  ledger: document.querySelector("#ledger"),
  resetDemo: document.querySelector("#resetDemo"),
};

let state = loadState();

function loadState() {
  const raw = localStorage.getItem(STORAGE_KEY);
  if (raw) {
    try {
      return JSON.parse(raw);
    } catch {
      localStorage.removeItem(STORAGE_KEY);
    }
  }

  const now = Date.now();
  const members = [
    makeMember("Minh", "MB Bank"),
    makeMember("Hieu", "Momo"),
    makeMember("Trang", "Techcombank"),
  ];

  return {
    members,
    ledger: [
      makeLedger("deposit", members[0].id, 500000, "Nap quy ban dau", now - 900000),
      makeLedger("deposit", members[1].id, 400000, "Nap quy ban dau", now - 800000),
      makeLedger("deposit", members[2].id, 300000, "Nap quy ban dau", now - 700000),
    ],
  };
}

function saveState() {
  localStorage.setItem(STORAGE_KEY, JSON.stringify(state));
}

function makeId(prefix) {
  return `${prefix}_${Math.random().toString(36).slice(2, 9)}_${Date.now().toString(36)}`;
}

function normalizeCode(value) {
  return value
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "")
    .replace(/[^a-z0-9]/gi, "")
    .toUpperCase()
    .slice(0, 12);
}

function makeMember(name, wallet) {
  const base = normalizeCode(name) || "TV";
  const suffix = String(Math.floor(10 + Math.random() * 89));
  return {
    id: makeId("member"),
    name: name.trim(),
    wallet: (wallet || "").trim(),
    code: `QAC${base}${suffix}`,
    createdAt: Date.now(),
  };
}

function makeLedger(type, memberId, amount, note, createdAt = Date.now(), extra = {}) {
  return {
    id: makeId("ledger"),
    type,
    memberId,
    amount: Number(amount) || 0,
    note: note || "",
    createdAt,
    ...extra,
  };
}

function money(value) {
  return currency.format(Math.round(Number(value) || 0)).replace("₫", "d");
}

function memberById(id) {
  return state.members.find((member) => member.id === id);
}

function getMemberTotals(memberId) {
  return state.ledger.reduce(
    (totals, entry) => {
      if (entry.memberId !== memberId) return totals;
      if (entry.type === "deposit") totals.deposited += entry.amount;
      if (entry.type === "event-share") totals.spent += entry.amount;
      return totals;
    },
    { deposited: 0, spent: 0 },
  );
}

function getBalance(memberId) {
  const totals = getMemberTotals(memberId);
  return totals.deposited - totals.spent;
}

function allTotals() {
  return state.members.reduce(
    (totals, member) => {
      const memberTotals = getMemberTotals(member.id);
      totals.deposited += memberTotals.deposited;
      totals.spent += memberTotals.spent;
      return totals;
    },
    { deposited: 0, spent: 0 },
  );
}

function render() {
  saveState();
  renderStats();
  renderMemberOptions();
  renderMembers();
  renderParticipants();
  renderQrBoard();
  renderEventPreview();
  renderLedger();
}

function renderStats() {
  const totals = allTotals();
  const pending = state.ledger.filter((entry) => entry.type === "pending").length;
  els.totalFund.textContent = money(totals.deposited - totals.spent);
  els.totalSpent.textContent = money(totals.spent);
  els.memberCount.textContent = state.members.length;
  els.pendingCount.textContent = pending;
}

function renderMemberOptions() {
  const optionHtml = state.members
    .map((member) => `<option value="${member.id}">${escapeHtml(member.name)}</option>`)
    .join("");

  els.depositMember.innerHTML = optionHtml;
  els.guestOwner.innerHTML = `<option value="">Khong gan</option>${optionHtml}`;
}

function renderMembers() {
  if (!state.members.length) {
    els.memberList.innerHTML = `<div class="empty">Chua co thanh vien nao.</div>`;
    return;
  }

  els.memberList.innerHTML = state.members
    .map((member) => {
      const totals = getMemberTotals(member.id);
      const balance = totals.deposited - totals.spent;
      const balanceClass = balance < 0 ? "negative" : "positive";
      return `
        <article class="member-card">
          <div class="member-top">
            <div>
              <p class="member-name">${escapeHtml(member.name)}</p>
              <div class="member-code">${escapeHtml(member.code)}</div>
            </div>
            <button class="ghost danger" type="button" data-remove-member="${member.id}">Xoa</button>
          </div>
          <div class="balance ${balanceClass}">${money(balance)}</div>
          <div class="mini-stats">
            <span>Da nop <strong>${money(totals.deposited)}</strong></span>
            <span>Da dung <strong>${money(totals.spent)}</strong></span>
          </div>
          <div class="muted">${escapeHtml(member.wallet || "Chua khai bao vi/gan hang")}</div>
        </article>
      `;
    })
    .join("");
}

function renderParticipants() {
  if (!state.members.length) {
    els.participantList.innerHTML = `<div class="empty">Them thanh vien truoc khi tao buoi.</div>`;
    return;
  }

  els.participantList.innerHTML = state.members
    .map(
      (member) => `
        <label class="check-row">
          <input type="checkbox" name="participant" value="${member.id}" checked />
          <span>${escapeHtml(member.name)}</span>
        </label>
      `,
    )
    .join("");
}

function renderQrBoard() {
  if (!state.members.length) {
    els.qrBoard.innerHTML = `<div class="empty">Chua co ma nap de hien thi.</div>`;
    return;
  }

  els.qrBoard.innerHTML = state.members
    .map(
      (member) => `
        <article class="qr-card">
          ${fakeQrSvg(member.code)}
          <div>
            <strong>${escapeHtml(member.name)}</strong>
            <div class="member-code">${escapeHtml(member.code)}</div>
          </div>
          <p class="hint">Noi dung CK: ${escapeHtml(member.code)}</p>
          <button class="ghost copy-code" type="button" data-copy-code="${member.code}">Copy ma</button>
        </article>
      `,
    )
    .join("");
}

function fakeQrSvg(code) {
  const bits = Array.from(code).map((char) => char.charCodeAt(0));
  const cells = [];
  for (let y = 0; y < 9; y += 1) {
    for (let x = 0; x < 9; x += 1) {
      const value = bits[(x + y * 3) % bits.length] + x * 11 + y * 17;
      if (value % 3 !== 0) {
        cells.push(`<rect x="${x * 10 + 14}" y="${y * 10 + 14}" width="8" height="8" rx="1" />`);
      }
    }
  }
  const finder = `
    <rect x="10" y="10" width="26" height="26" rx="3" fill="none" stroke="currentColor" stroke-width="5" />
    <rect x="82" y="10" width="26" height="26" rx="3" fill="none" stroke="currentColor" stroke-width="5" />
    <rect x="10" y="82" width="26" height="26" rx="3" fill="none" stroke="currentColor" stroke-width="5" />
  `;
  return `<svg class="qr-code" viewBox="0 0 118 118" role="img" aria-label="Ma nap ${escapeHtml(code)}">${finder}<g fill="currentColor">${cells.join("")}</g></svg>`;
}

function renderEventPreview() {
  const shares = calculateEventShares();
  if (!shares.length) {
    els.eventPreview.innerHTML = `<div class="empty">Chon thanh vien va nhap tong bill de xem truoc phan bo.</div>`;
    return;
  }

  els.eventPreview.innerHTML = shares
    .map(
      (share) => `
        <div class="split-row">
          <div>
            <strong>${escapeHtml(share.member.name)}</strong>
            <div class="ledger-meta">${escapeHtml(share.reason)}</div>
          </div>
          <strong>${money(share.amount)}</strong>
        </div>
      `,
    )
    .join("");
}

function renderLedger() {
  if (!state.ledger.length) {
    els.ledger.innerHTML = `<div class="empty">Chua co lich su giao dich.</div>`;
    return;
  }

  els.ledger.innerHTML = [...state.ledger]
    .sort((a, b) => b.createdAt - a.createdAt)
    .map((entry) => {
      const member = memberById(entry.memberId);
      const sign = entry.type === "deposit" ? "+" : entry.type === "event-share" ? "-" : "";
      const amountClass = entry.type === "deposit" ? "in" : entry.type === "pending" ? "pending" : "out";
      const title =
        entry.type === "deposit"
          ? "Nop quy"
          : entry.type === "event-share"
            ? `Chi phi: ${entry.eventName || "Buoi an/nhau"}`
            : "Chua nhan dien";
      return `
        <article class="ledger-row">
          <div>
            <strong>${title}</strong>
            <div class="ledger-meta">
              ${member ? escapeHtml(member.name) : "Khong ro thanh vien"} - ${new Date(entry.createdAt).toLocaleString("vi-VN")}
            </div>
            <div class="muted">${escapeHtml(entry.note || "")}</div>
          </div>
          <div class="ledger-amount ${amountClass}">${sign}${money(entry.amount)}</div>
        </article>
      `;
    })
    .join("");
}

function selectedParticipantIds() {
  return Array.from(document.querySelectorAll('input[name="participant"]:checked')).map((input) => input.value);
}

function calculateEventShares() {
  const total = Number(els.eventAmount.value) || 0;
  const guestAmount = Number(els.guestAmount.value) || 0;
  const participantIds = selectedParticipantIds();
  if (!total || !participantIds.length) return [];

  const participants = participantIds.map(memberById).filter(Boolean);
  const guestOwner = memberById(els.guestOwner.value);
  const mode = els.splitMode.value;
  let baseTotal = total;
  const shares = [];

  if (mode === "equal" && guestAmount > 0) {
    baseTotal = Math.max(0, total - guestAmount);
  }

  const baseShare = Math.floor(baseTotal / participants.length);
  let remainder = baseTotal - baseShare * participants.length;

  for (const member of participants) {
    let amount = baseShare;
    if (remainder > 0) {
      amount += 1;
      remainder -= 1;
    }
    shares.push({
      member,
      amount,
      reason: mode === "equal" ? "Chia deu sau khi tru tien khach la" : "Chia deu tong bill",
    });
  }

  if (mode === "owner-pays-guest" && guestOwner && guestAmount > 0) {
    const ownerShare = shares.find((share) => share.member.id === guestOwner.id);
    if (ownerShare) {
      ownerShare.amount += guestAmount;
      ownerShare.reason = `${ownerShare.reason}, cong phan khach la ${money(guestAmount)}`;
    } else {
      shares.push({
        member: guestOwner,
        amount: guestAmount,
        reason: "Tra rieng phan khach la duoc gan",
      });
    }
  }

  return shares;
}

function addDeposit(memberId, amount, note) {
  state.ledger.push(makeLedger("deposit", memberId, amount, note));
}

function escapeHtml(value) {
  return String(value)
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&#039;");
}

function bindEvents() {
  document.querySelectorAll(".tab").forEach((button) => {
    button.addEventListener("click", () => {
      document.querySelectorAll(".tab").forEach((tab) => tab.classList.remove("active"));
      document.querySelectorAll(".tab-panel").forEach((panel) => panel.classList.remove("active"));
      button.classList.add("active");
      document.querySelector(`#${button.dataset.tab}`).classList.add("active");
    });
  });

  els.memberForm.addEventListener("submit", (event) => {
    event.preventDefault();
    const name = els.memberName.value.trim();
    if (!name) return;
    state.members.push(makeMember(name, els.memberWallet.value));
    els.memberForm.reset();
    render();
  });

  els.memberList.addEventListener("click", (event) => {
    const id = event.target.dataset.removeMember;
    if (!id) return;
    const hasLedger = state.ledger.some((entry) => entry.memberId === id);
    if (hasLedger) {
      alert("Thanh vien da co giao dich, khong nen xoa de giu lich su. Ban co the tao trang thai 'ngung tham gia' o ban that.");
      return;
    }
    state.members = state.members.filter((member) => member.id !== id);
    render();
  });

  els.depositForm.addEventListener("submit", (event) => {
    event.preventDefault();
    addDeposit(els.depositMember.value, Number(els.depositAmount.value), els.depositNote.value || "Nop quy thu cong");
    els.depositForm.reset();
    render();
  });

  els.bankForm.addEventListener("submit", (event) => {
    event.preventDefault();
    const content = els.bankContent.value.toUpperCase();
    const amount = Number(els.bankAmount.value) || 0;
    const member = state.members.find((item) => content.includes(item.code));
    if (member) {
      addDeposit(member.id, amount, `Tu nhan dien sao ke: ${els.bankContent.value}`);
    } else {
      state.ledger.push(makeLedger("pending", null, amount, `Khong tim thay ma nap trong: ${els.bankContent.value}`));
    }
    els.bankForm.reset();
    render();
  });

  els.qrBoard.addEventListener("click", async (event) => {
    const code = event.target.dataset.copyCode;
    if (!code) return;
    try {
      await navigator.clipboard.writeText(code);
      event.target.textContent = "Da copy";
      setTimeout(() => {
        event.target.textContent = "Copy ma";
      }, 1000);
    } catch {
      alert(code);
    }
  });

  ["input", "change"].forEach((eventName) => {
    els.eventForm.addEventListener(eventName, renderEventPreview);
  });

  els.eventForm.addEventListener("submit", (event) => {
    event.preventDefault();
    const shares = calculateEventShares();
    if (!shares.length) {
      alert("Can nhap tong bill va chon it nhat mot thanh vien.");
      return;
    }
    const eventName = els.eventName.value.trim() || "Buoi an/nhau";
    for (const share of shares) {
      state.ledger.push(
        makeLedger("event-share", share.member.id, share.amount, share.reason, Date.now(), {
          eventName,
        }),
      );
    }
    els.eventForm.reset();
    render();
  });

  els.resetDemo.addEventListener("click", () => {
    localStorage.removeItem(STORAGE_KEY);
    state = loadState();
    render();
  });
}

bindEvents();
render();
