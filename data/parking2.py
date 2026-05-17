import cv2
from ultralytics import YOLO

model = YOLO("yolov8n.pt")

video_path = "input.mp4"

cap = cv2.VideoCapture(video_path)

width = int(cap.get(cv2.CAP_PROP_FRAME_WIDTH))
height = int(cap.get(cv2.CAP_PROP_FRAME_HEIGHT))
fps = cap.get(cv2.CAP_PROP_FPS)

out = cv2.VideoWriter(
    "output3.avi",
    cv2.VideoWriter_fourcc(*"MJPG"),
    fps,
    (width, height)
)

# =========================
# Track ID GROUPS
# =========================

groups = {

    1: [1,192],
    2: [2],
    3: [3,177,207],
    4: [4,24,66,75,85,247,256,265,293,363,371],
    5: [5,9],
    6: [6,89,91],
    7: [7,90,271,405,460],
    10: [10],
    12: [12],
    13: [13,32,65,87,95,104,124,209,262,291,299,539],
    22: [22],
    42: [42,45],
    49: [49],
    55: [55],
    58: [58],
    59: [59,64],
    68: [68,71],
    96: [96,98],
    106: [106,117],
    120: [120],
    158: [158,283,315,439,459,533],
    205: [205,217],
    300: [300,302,305],
    313: [313,318],
    324: [324,334],
    345: [345,348],
    389: [389,391],
    392: [392,408,434,454],
    543: [543],
    558: [558,560],
    561: [561],
    572: [572],
    574: [574,582]
}

# =========================
# Id -> MASTER ID
# =========================

id_map = {}

for master_id, ids in groups.items():

    for i in ids:
        id_map[i] = master_id

# =========================
# Plates
# =========================

plates = {

    1: "KR 4JX21",
    2: "KRA 91PF",
    3: "KK 7L221",
    4: "WX 7788K",
    5: "GD 52LA",
    6: "PO 8CE44",
    7: "DW 31KF",

    10: "LU 4H882",
    12: "EL 93PK",
    13: "KR 7AT11",
    22: "ZS 1LE92",

    42: "KGR 4X221",
    49: "SCI 88FK",
    55: "KLI 2PA77",
    58: "KR 91UU2",

    59: "WA 7CC31",
    68: "KR 6M882",
    96: "KRA 22EF",
    106: "SK 52XA",

    120: "DW 8L992",
    158: "GD 71PA",
    205: "PO 44CX2",

    300: "KR 8XY11",
    313: "WA 3EE88",
    324: "LU 5KK21",

    345: "EL 991LA",
    389: "ZS 7TR55",
    392: "SCI 2AC11",

    # Podejrzany
    543: "KR4B2137",

    558: "KGR 8PF22",
    561: "DW 5AF81",
    572: "PO 3CE77",
    574: "GD 1XP42"
}

# =========================
# Tracking
# =========================

results = model.track(
    source=video_path,
    tracker="bytetrack.yaml",
    conf=0.5,
    classes=[2],
    persist=True,
    stream=True
)

for frame_idx, result in enumerate(results):

    frame = result.orig_img

    if result.boxes is not None:

        for box in result.boxes:

            raw_id = int(box.id) if box.id is not None else -1

            # ignoruj nieznane auta
            if raw_id not in id_map:
                continue

            master_id = id_map[raw_id]

            plate = plates[master_id]

            x1, y1, x2, y2 = map(int, box.xyxy[0])

            # kolor samochodów
            color = (0,255,0)


            # Box
            cv2.rectangle(
                frame,
                (x1, y1),
                (x2, y2),
                color,
                2
            )

            # Label
            cv2.putText(
                frame,
                plate,
                (x1, y1 - 10),
                cv2.FONT_HERSHEY_SIMPLEX,
                0.7,
                color,
                2
            )

    out.write(frame)

    print(f"Frame {frame_idx}")

    cv2.imshow("CCTV", frame)

    if cv2.waitKey(1) & 0xFF == ord('q'):
        break

cap.release()
out.release()

cv2.destroyAllWindows()

print("DONE -> output.avi")
