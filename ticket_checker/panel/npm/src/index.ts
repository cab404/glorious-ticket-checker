import { default as QrScanner } from "qr-scanner";

export default start_qr;
declare var qrworker: string;
QrScanner.WORKER_PATH = qrworker!;

function start_qr(elem: HTMLVideoElement) {
  var prev_code = "";

  let scanner = new QrScanner(
    elem,
    (decoded) => {
      if (decoded != prev_code && decoded != "") {
        new_code(decoded);
        prev_code = decoded;
      }
      console.log(decoded);
    },
    undefined,
    300,
    "environment"
  );

  elem.ondblclick = (ev) => {
    scanner.toggleFlash();
  };

  scanner.start().then(() => {
    section(null);
  });
}

function progressMessage(progressMessage: string) {
  document.getElementById("ticket-progress-state")!.innerText = progressMessage;
  section("ticket-progress");
}

const sections = ["ticket-progress", "ticket-info", "ticket-error"] as const;

type ElemType<Arr extends readonly unknown[]> =
  Arr extends readonly (infer Elem)[] ? Elem : never;

function section(sectionId: ElemType<typeof sections> | null) {
  for (const i of sections) {
    document.getElementById(i)!.style.visibility =
      i == sectionId ? "visible" : "collapse";
  }
}

function new_code(sectionId: string) {
  progressMessage("Loading...");

  fetch("/ticket/" + sectionId)
    .then((r) => r.json())
    .then((resp) => {
      if ("error" in resp) {
        section("ticket-error");
        document.getElementById("ticket-error-title")!.textContent = resp.error;
        document.getElementById("ticket-error-text")!.textContent =
          "I dunno man, looks kinda sus";
      } else {
        section("ticket-info");
        document.getElementById("ticket-name")!.innerText = resp.full_name;
        document.getElementById("ticket-passes")!.innerText = resp.passes;
        document.getElementById("ticket-email")!.innerText = resp.email;
        document.getElementById("ticket-order")!.innerText = resp.order;
        document.getElementById("ticket-cost")!.innerText = resp.cost;
        document.getElementById("ticket-category")!.innerText = resp.category;
        document.getElementById("ticket-comments")!.innerText = resp.comments;
      }
    })
    .catch((err) => {
      section("ticket-error");
      console.log(err);
      document.getElementById("ticket-error-title")!.textContent = err;
      document.getElementById("ticket-error-text")!.textContent =
        "Something weird!";
    });
}

progressMessage("Starting up QR service...");
start_qr(document.getElementById("scanner") as HTMLVideoElement);
