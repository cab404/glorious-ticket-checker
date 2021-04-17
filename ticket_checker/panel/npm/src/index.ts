import { default as QrScanner } from "qr-scanner"

export default start_qr
declare var qrworker: string;
QrScanner.WORKER_PATH = qrworker!

function start_qr(elem: HTMLVideoElement) {
    var prev_code = "";

    let scanner = new QrScanner(
        elem,
        (decoded) => {
            if (decoded != prev_code && decoded != "") {
                new_code(decoded)
                prev_code = decoded
            }
            console.log(decoded)
        },
        (error) => {
            console.log(error)
        },
        300,
        "environment"
    )

    scanner.start().then(() => {
        console.log("started")
    })

}

function new_code(code: string) {
    let title = document.getElementById("ticket-code")!
    title.innerHTML = `
        Loading ${code}
    `
    fetch("/ticket/" + code)
        .then(r => r.json())
        .then(resp => {
            title.innerHTML = `
                <h1>${resp.full_name}</h1>
                <h3>Category: ${resp.category}
                ${resp.order != null ? `
                | Order ${resp.order}
                ` : ""}
                </h3>

                <h3>Passed: ${resp.passes} times</h3>
                
                ${(resp.comments as string) != "" ? `
                <h3>${resp.comments}</h3>
                ` : `
                <i>No comments for you.<i>
                `}
            `
        })

}

start_qr(document.getElementById("scanner") as HTMLVideoElement)
