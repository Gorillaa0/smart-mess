import os
import sys
from PIL import Image, ImageDraw, ImageFont
from reportlab.lib.pagesizes import A4
from reportlab.lib import colors
from reportlab.lib.units import inch
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.platypus import (
    SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle, Image as RLImage, KeepTogether, HRFlowable
)
from reportlab.pdfgen import canvas

def create_architecture_diagram(output_path):
    width = 1600
    height = 900
    img = Image.new('RGB', (width, height), color='#0F172A') # Dark slate theme
    draw = ImageDraw.Draw(img)

    # Helper function for drawing rounded boxes
    def draw_box(x, y, w, h, bg_color, border_color, title, subtitle_lines, icon_label=None):
        radius = 16
        draw.rounded_rectangle([x, y, x + w, y + h], radius=radius, fill=bg_color, outline=border_color, width=2)
        # Header strip
        draw.rounded_rectangle([x, y, x + w, y + 42], radius=radius, fill=border_color, outline=None)
        draw.rectangle([x, y + 25, x + w, y + 42], fill=border_color) # Flatten bottom radius of header
        
        # Title
        draw.text((x + 16, y + 10), title, fill='#FFFFFF')
        
        # Subtitles
        cy = y + 54
        for line in subtitle_lines:
            draw.text((x + 16, cy), line, fill='#E2E8F0')
            cy += 22

    def draw_arrow(x1, y1, x2, y2, color='#38BDF8', label=None):
        draw.line([x1, y1, x2, y2], fill=color, width=3)
        # Arrowhead
        if x2 > x1: # Horizontal right
            draw.polygon([(x2, y2), (x2 - 10, y2 - 6), (x2 - 10, y2 + 6)], fill=color)
            if label:
                draw.text(((x1 + x2)//2 - 30, y1 - 18), label, fill='#94A3B8')
        elif y2 > y1: # Vertical down
            draw.polygon([(x2, y2), (x2 - 6, y2 - 10), (x2 + 6, y2 - 10)], fill=color)
            if label:
                draw.text((x1 + 10, (y1 + y2)//2 - 10), label, fill='#94A3B8')
        elif x2 < x1: # Horizontal left
            draw.polygon([(x2, y2), (x2 + 10, y2 - 6), (x2 + 10, y2 + 6)], fill=color)
            if label:
                draw.text(((x1 + x2)//2 - 30, y1 - 18), label, fill='#94A3B8')

    # Draw Title Header on image
    draw.text((50, 30), "SMART MESS - END-TO-END SYSTEM ARCHITECTURE FLOW", fill="#38BDF8")
    draw.text((50, 60), "Real-time sync between Mobile App, Web Portal, ML Service, and Cloud Firestore", fill="#94A3B8")

    # Layer 1: Client Applications (Left Column)
    draw.text((60, 110), "1. CLIENT INTERACTION LAYER", fill="#34D399")
    draw_box(60, 140, 380, 170, '#1E293B', '#059669', "Flutter Mobile App (Students & Staff)", [
        "• Cross-Platform Dart & Riverpod 2.x",
        "• MobileScanner QR Counter Verification",
        "• Real-time Menu, Mess-Off & Billing Log",
        "• In-App Pop-up Push Overlay"
    ])

    draw_box(60, 350, 380, 170, '#1E293B', '#0284C7', "React 18 Web Dashboard (Manager & Admin)", [
        "• React 18, TypeScript 5.4, Vite & Tailwind",
        "• Live Attendance Feed & Student Roster",
        "• Printable Static / Dynamic QR Generator",
        "• AI Prediction & Food Prep Approval"
    ])

    draw_box(60, 560, 380, 150, '#1E293B', '#D97706', "Physical Dining Hall Turnstile / Wall", [
        "• Static Printable Counter QR Poster",
        "• Camera Scan by Students on Arrival",
        "• Zero Hardware Cost Deployment"
    ])

    # Layer 2: API & Gateway Layer (Middle-Left)
    draw.text((510, 110), "2. BACKEND & API GATEWAY", fill="#38BDF8")
    draw_box(510, 200, 360, 200, '#1E293B', '#6366F1', "Express.js REST API & Cloud Run", [
        "• Node.js & TypeScript Container",
        "• JWT Verification & Security Middleware",
        "• QR Code Token Verification Service",
        "• Itemized Consumption Billing Engine",
        "• Audit Logging & Security Checks"
    ])

    draw_box(510, 440, 360, 190, '#1E293B', '#8B5CF6', "Firebase Cloud Functions v2", [
        "• Serverless Background Triggers",
        "• Scheduled Monthly Auto-Billing Cron",
        "• FCM Push Notification Dispatcher",
        "• Admin Account Lifecycle Automation"
    ])

    # Layer 3: Database & Cloud Services (Middle-Right)
    draw.text((940, 110), "3. DATA & AUTHENTICATION LAYER", fill="#F43F5E")
    draw_box(940, 180, 300, 250, '#1E293B', '#E11D48', "Google Cloud Firestore", [
        "• NoSQL Real-Time Collections:",
        "  - /mealAttendance (QR Scans)",
        "  - /students & /users",
        "  - /meals & /messOffs",
        "  - /predictions & /wastage",
        "  - /notifications & /bills",
        "• Sub-second Live Snapshots"
    ])

    draw_box(940, 470, 300, 160, '#1E293B', '#EA580C', "Firebase Authentication & FCM", [
        "• JWT Token Auth & Custom Claims",
        "• Role-Based Access Control",
        "• Firebase Cloud Messaging",
        "• Secure Credential Storage"
    ])

    # Layer 4: AI & ML Prediction Microservice (Right Column)
    draw.text((1280, 110), "4. AI / ML PREDICTION ENGINE", fill="#F59E0B")
    draw_box(1280, 250, 280, 320, '#1E293B', '#D97706', "Python FastAPI ML Service", [
        "• Python 3.12, Uvicorn, Scikit-Learn",
        "• RandomForestRegressor (100 Trees)",
        "• Inputs: Historical Attendance,",
        "  Exams, Holidays, Day of Week,",
        "  Mess-Off Counts, Past Wastage",
        "• Outputs: Predicted Demand,",
        "  +3% Safety Buffer Quantity",
        "• Continuous Model Retraining"
    ])

    # Connect Arrows
    # Client -> Backend
    draw_arrow(440, 220, 510, 260, '#34D399', "REST / Auth")
    draw_arrow(440, 420, 510, 320, '#38BDF8', "API Calls")
    draw_arrow(440, 600, 250, 310, '#F59E0B', "Scans QR")

    # Backend -> Firestore
    draw_arrow(870, 280, 940, 280, '#6366F1', "Reads/Writes")
    draw_arrow(870, 520, 940, 520, '#8B5CF6', "Triggers")

    # Backend -> ML Engine
    draw_arrow(870, 340, 1280, 340, '#F59E0B', "POST /predict")
    draw_arrow(1280, 380, 940, 380, '#34D399', "Saves Prediction")

    # Firestore -> Clients (Real-time sync)
    draw_arrow(940, 320, 440, 460, '#38BDF8', "Live Stream Sync")
    draw_arrow(940, 220, 440, 200, '#34D399', "Live Stream Sync")

    # Save image
    img.save(output_path, "PNG", quality=95)
    print(f"Architecture diagram generated at: {output_path}")

class NumberedCanvas(canvas.Canvas):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self._saved_page_states = []

    def showPage(self):
        self._saved_page_states.append(dict(self.__dict__))
        self._startPage()

    def save(self):
        num_pages = len(self._saved_page_states)
        for state in self._saved_page_states:
            self.__dict__.update(state)
            self.draw_page_decorations(num_pages)
            super().showPage()
        super().save()

    def draw_page_decorations(self, page_count):
        self.saveState()
        self.setFont("Helvetica", 8)
        self.setFillColor(colors.HexColor("#64748B"))
        
        # Header (pages > 1)
        if self._pageNumber > 1:
            self.drawString(54, 800, "SMART MESS - Complete Technology Stack & System Architecture Specification")
            self.setStrokeColor(colors.HexColor("#CBD5E1"))
            self.setLineWidth(0.5)
            self.line(54, 792, 541, 792)

        # Footer
        self.setStrokeColor(colors.HexColor("#CBD5E1"))
        self.setLineWidth(0.5)
        self.line(54, 45, 541, 45)
        self.drawString(54, 32, "Confidential & Institutional • Smart Mess Food Management System")
        self.drawRightString(541, 32, f"Page {self._pageNumber} of {page_count}")
        self.restoreState()

def generate_pdf(pdf_path, diagram_path):
    doc = SimpleDocTemplate(
        pdf_path,
        pagesize=A4,
        leftMargin=45,
        rightMargin=45,
        topMargin=54,
        bottomMargin=54
    )

    styles = getSampleStyleSheet()

    # Custom typography styles
    title_style = ParagraphStyle(
        'DocTitle',
        fontName='Helvetica-Bold',
        fontSize=22,
        leading=26,
        textColor=colors.HexColor('#1B5E20'),
        spaceAfter=4
    )
    
    subtitle_style = ParagraphStyle(
        'DocSubTitle',
        fontName='Helvetica-Bold',
        fontSize=12,
        leading=16,
        textColor=colors.HexColor('#2E7D32'),
        spaceAfter=12
    )

    meta_style = ParagraphStyle(
        'DocMeta',
        fontName='Helvetica',
        fontSize=9,
        leading=12,
        textColor=colors.HexColor('#64748B'),
        spaceAfter=14
    )

    h1_style = ParagraphStyle(
        'Heading1',
        fontName='Helvetica-Bold',
        fontSize=13,
        leading=17,
        textColor=colors.HexColor('#0F172A'),
        spaceBefore=14,
        spaceAfter=6,
        keepWithNext=True
    )

    h2_style = ParagraphStyle(
        'Heading2',
        fontName='Helvetica-Bold',
        fontSize=10.5,
        leading=14,
        textColor=colors.HexColor('#1B5E20'),
        spaceBefore=8,
        spaceAfter=4,
        keepWithNext=True
    )

    body_style = ParagraphStyle(
        'Body',
        fontName='Helvetica',
        fontSize=8.5,
        leading=12,
        textColor=colors.HexColor('#334155'),
        spaceAfter=6
    )

    bullet_style = ParagraphStyle(
        'Bullet',
        fontName='Helvetica',
        fontSize=8.5,
        leading=12,
        textColor=colors.HexColor('#334155'),
        leftIndent=12,
        firstLineIndent=-8,
        spaceAfter=3
    )

    table_header_style = ParagraphStyle(
        'TableHeader',
        fontName='Helvetica-Bold',
        fontSize=8,
        leading=10,
        textColor=colors.white,
        alignment=0
    )

    table_body_style = ParagraphStyle(
        'TableBody',
        fontName='Helvetica',
        fontSize=7.5,
        leading=10,
        textColor=colors.HexColor('#1E293B')
    )

    table_bold_style = ParagraphStyle(
        'TableBold',
        fontName='Helvetica-Bold',
        fontSize=7.5,
        leading=10,
        textColor=colors.HexColor('#0F172A')
    )

    story = []

    # Title & Header
    story.append(Paragraph("SMART MESS SYSTEM", title_style))
    story.append(Paragraph("Comprehensive Technology Stack & Machine Learning Architecture Specification", subtitle_style))
    story.append(Paragraph("<b>Version:</b> 2.4 (Production Ready) &nbsp;|&nbsp; <b>Institution:</b> Central Hostel Mess System &nbsp;|&nbsp; <b>Date:</b> August 2026", meta_style))
    story.append(HRFlowable(width="100%", thickness=1.5, color=colors.HexColor('#1B5E20'), spaceAfter=12))

    # Executive Overview
    story.append(Paragraph("1. Executive Summary & Core Objectives", h1_style))
    story.append(Paragraph(
        "<b>Smart Mess</b> is a scalable, end-to-end intelligent food management platform designed for universities and institutional hostels. "
        "The system replaces manual paper registers with instant QR-code meal attendance, eliminates kitchen overproduction using machine learning predictive models, "
        "automates consumption-based diet billing, and gives hostel administration real-time transparency into dining metrics and student welfare.",
        body_style
    ))
    story.append(Paragraph(
        "<b>Key System Outcomes:</b> (1) Over 30% reduction in daily food waste, (2) Zero-hardware turnstile scanning using printed static QR codes or live counter screens, "
        "(3) Accurate consumption-based accounting based on actual verified scans, and (4) Predictive kitchen preparation approvals.",
        body_style
    ))

    story.append(Spacer(1, 6))

    # System Architecture Diagram
    story.append(Paragraph("2. High-Level System Architecture Flow", h1_style))
    story.append(Paragraph("The diagram below illustrates the end-to-end data pipeline connecting client interfaces, backend microservices, real-time cloud databases, and the Python ML prediction service:", body_style))
    
    if os.path.exists(diagram_path):
        # Fit diagram onto A4 width (approx 500pt width, 280pt height)
        story.append(RLImage(diagram_path, width=500, height=275))
    
    story.append(Spacer(1, 10))

    # Tech Stack Table
    story.append(Paragraph("3. Detailed Technology Stack Breakdown", h1_style))

    stack_data = [
        [
            Paragraph("Layer / Subsystem", table_header_style),
            Paragraph("Core Technologies & Frameworks", table_header_style),
            Paragraph("Key Libraries / Packages", table_header_style),
            Paragraph("Role & Capabilities in System", table_header_style)
        ],
        [
            Paragraph("<b>Mobile App</b><br/>(Students & Staff)", table_bold_style),
            Paragraph("Flutter 3.x<br/>Dart 3.x", table_body_style),
            Paragraph("• flutter_riverpod 2.5<br/>• go_router 13.x<br/>• mobile_scanner 5.x<br/>• shared_preferences 2.2<br/>• qr_flutter 4.x", table_body_style),
            Paragraph("Cross-platform Android & iOS client. Handles camera QR scanning, live meal calendar, mess-off submissions, consumption billing ledger, and real-time pop-up push announcements.", table_body_style)
        ],
        [
            Paragraph("<b>Web Portal</b><br/>(Manager & Admin)", table_bold_style),
            Paragraph("React 18.3<br/>TypeScript 5.4<br/>Vite 5.3", table_body_style),
            Paragraph("• Tailwind CSS 3.4<br/>• Zustand 4.5<br/>• TanStack Query 5.40<br/>• Recharts 2.12<br/>• Lucide React Icons", table_body_style),
            Paragraph("Institutional management dashboard. Displays live counter feed, printable static QR poster generator, daily meal scheduling, student roster, and AI demand approvals.", table_body_style)
        ],
        [
            Paragraph("<b>Backend API &amp; Microservices</b>", table_bold_style),
            Paragraph("Node.js 18+<br/>Express.js REST<br/>Google Cloud Run", table_body_style),
            Paragraph("• firebase-admin 14.3<br/>• cors 2.8<br/>• node-cron 3.0<br/>• dotenv 16.4", table_body_style),
            Paragraph("Handles authenticated REST APIs, role-based JWT validation, QR transaction verification, automated monthly billing calculations, and immutable audit logging.", table_body_style)
        ],
        [
            Paragraph("<b>Cloud Functions &amp; Serverless</b>", table_bold_style),
            Paragraph("Firebase Functions v2<br/>Google Cloud", table_body_style),
            Paragraph("• firebase-functions v2<br/>• Cloud Scheduler<br/>• Cloud Tasks", table_body_style),
            Paragraph("Automated cron routines: monthly billing rollups, mess-off deadline enforcement, complaint status triggers, and FCM push notifications.", table_body_style)
        ],
        [
            Paragraph("<b>Database &amp; Storage Layer</b>", table_bold_style),
            Paragraph("Google Cloud Firestore<br/>NoSQL Database", table_body_style),
            Paragraph("• Sub-second snapshots<br/>• Firestore Security Rules<br/>• Composite Indexes", table_body_style),
            Paragraph("Scalable NoSQL store for mealAttendance, students, meals, messOffs, predictions, wastage logs, and billing ledgers with real-time reactive sync.", table_body_style)
        ],
        [
            Paragraph("<b>Authentication &amp; Security</b>", table_bold_style),
            Paragraph("Firebase Auth &amp;<br/>Custom Claims", table_body_style),
            Paragraph("• JWT Bearer Tokens<br/>• Role Claims (RBAC)<br/>• Session Persistence", table_body_style),
            Paragraph("Multi-role identity management (Students, Mess Managers, Institute Admins) with persistent device tokens and secure password verification.", table_body_style)
        ],
        [
            Paragraph("<b>Machine Learning Engine</b>", table_bold_style),
            Paragraph("Python 3.12<br/>FastAPI 0.111<br/>Uvicorn 0.30", table_body_style),
            Paragraph("• scikit-learn 1.4.2<br/>• NumPy 1.26<br/>• Pandas 2.2<br/>• Joblib 1.4", table_body_style),
            Paragraph("Ensemble Random Forest regressor for headcount forecasting, 3-5% safety buffer calculation, accuracy tracking, and feature importance analysis.", table_body_style)
        ],
        [
            Paragraph("<b>Hosting &amp; Cloud Infra</b>", table_bold_style),
            Paragraph("Firebase Hosting &amp;<br/>Google Cloud Run", table_body_style),
            Paragraph("• Global CDN / SSL<br/>• Docker Containers<br/>• Zero-Downtime Deploy", table_body_style),
            Paragraph("Production web application hosting at smart-mess-sih.web.app and serverless container execution.", table_body_style)
        ]
    ]

    t = Table(stack_data, colWidths=[80, 95, 125, 200])
    t.setStyle(TableStyle([
        ('BACKGROUND', (0, 0), (-1, 0), colors.HexColor('#1B5E20')),
        ('TEXTCOLOR', (0, 0), (-1, 0), colors.white),
        ('ALIGN', (0, 0), (-1, -1), 'LEFT'),
        ('VALIGN', (0, 0), (-1, -1), 'TOP'),
        ('TOPPADDING', (0, 0), (-1, -1), 4),
        ('BOTTOMPADDING', (0, 0), (-1, -1), 4),
        ('LEFTPADDING', (0, 0), (-1, -1), 5),
        ('RIGHTPADDING', (0, 0), (-1, -1), 5),
        ('GRID', (0, 0), (-1, -1), 0.5, colors.HexColor('#CBD5E1')),
        ('ROWBACKGROUNDS', (0, 1), (-1, -1), [colors.HexColor('#FFFFFF'), colors.HexColor('#F8FAFC')])
    ]))

    story.append(t)
    story.append(Spacer(1, 10))

    # Machine Learning Architecture in Detail
    story.append(Paragraph("4. Machine Learning & Predictive Analytics Pipeline", h1_style))
    story.append(Paragraph(
        "The core mathematical innovation of Smart Mess is its <b>Dynamic Headcount Prediction Pipeline</b>. "
        "Instead of cooking fixed quantities that lead to massive food waste on weekends or low-turnout days, the ML model predicts exact dining attendance 2 to 3 hours prior to meal service.",
        body_style
    ))

    story.append(Paragraph("<b>A. Machine Learning Model Architecture:</b>", h2_style))
    story.append(Paragraph("• <b>Algorithm:</b> <code>RandomForestRegressor</code> (100 Estimator Trees with bootstrap aggregation) paired with an analytical fallback baseline.", bullet_style))
    story.append(Paragraph("• <b>Evaluation Metrics:</b> Mean Absolute Error (MAE), Root Mean Squared Error (RMSE), and R² Score evaluated across cross-validation splits.", bullet_style))
    story.append(Paragraph("• <b>Inference Latency:</b> Sub-15ms prediction response served via asynchronous FastAPI endpoints (<code>POST /predict</code>).", bullet_style))

    story.append(Paragraph("<b>B. Input Feature Vector (12 Key Variables):</b>", h2_style))
    features_text = (
        "1. <b>meal_type_encoded</b> (Breakfast = 0, Lunch = 1, Dinner = 2)<br/>"
        "2. <b>day_of_week</b> (0 = Monday ... 6 = Sunday; captures weekend slump and Sunday feast surges)<br/>"
        "3. <b>total_active_students</b> (Active enrolled boarders in the specific hostel mess)<br/>"
        "4. <b>mess_off_count</b> (Live count of verified opt-outs submitted prior to cutoff deadline)<br/>"
        "5. <b>is_exam_day</b> (Boolean: academic exam impact on attendance)<br/>"
        "6. <b>is_holiday</b> (Boolean: holidays / long weekends where students travel home)<br/>"
        "7. <b>is_special_event</b> (Festivals, cultural nights, sports tournaments)<br/>"
        "8. <b>event_impact_encoded</b> (None = 0, Low = 1, Medium = 2, High = 3)<br/>"
        "9. <b>historical_avg_attendance</b> (Rolling 30-day moving average for identical meal type)<br/>"
        "10. <b>historical_avg_wastage</b> (Rolling wastage baseline in kilograms)<br/>"
        "11. <b>prev_day_attendance</b> (Autoregressive lag feature capturing immediate attendance momentum)<br/>"
        "12. <b>hostel_occupancy_rate</b> (Live ratio of students physically residing on campus)"
    )
    story.append(Paragraph(features_text, body_style))

    story.append(Paragraph("<b>C. Safety Buffer & Kitchen Recommendation Formula:</b>", h2_style))
    story.append(Paragraph(
        "To prevent undercooking and food shortages while minimizing wastage, the system computes a safety buffer and confidence interval:<br/>"
        "&nbsp;&nbsp;&nbsp;&nbsp;<b>Recommended Quantity</b> = Predicted Attendance &times; 1.03 (3% Safety Buffer)<br/>"
        "&nbsp;&nbsp;&nbsp;&nbsp;<b>Confidence Interval Range</b> = Predicted Attendance &plusmn; 5%<br/>"
        "The Mess Manager reviews this prediction on their mobile app or web portal and clicks <b>Approve Cooking Quantity</b> with 1 tap.",
        body_style
    ))

    story.append(Spacer(1, 8))

    # Real-Time Operational Flows
    story.append(Paragraph("5. Key Operational & Business Logic Workflows", h1_style))
    
    story.append(Paragraph("<b>1. QR Attendance Turnstile Verification:</b>", h2_style))
    story.append(Paragraph(
        "• A permanent static QR poster is pasted on the dining hall wall or counter (Zero hardware cost).<br/>"
        "• The student points their smartphone camera via the Flutter app. The app securely bundles the student's authenticated ID, the scanned mess token, server timestamp, and active meal slot.<br/>"
        "• An atomic Firestore transaction verifies student eligibility and generates an immutable record in <code>/mealAttendance/</code>.<br/>"
        "• Anti-duplication rules prevent scanning twice for the same meal.",
        body_style
    ))

    story.append(Paragraph("<b>2. Mess-Off Opt-Out & Rebate System:</b>", h2_style))
    story.append(Paragraph(
        "• Students can opt out of meals before the strict cutoff deadline (Breakfast: 07:00 AM, Lunch: 11:00 AM, Dinner: 06:00 PM).<br/>"
        "• Validated opt-outs reduce the kitchen's predicted preparation quantity in real-time, preventing surplus cooking.",
        body_style
    ))

    story.append(Paragraph("<b>3. Real-Time Itemized Consumption Billing:</b>", h2_style))
    story.append(Paragraph(
        "• <b>Advance Deposit:</b> Students start with their institutional advance payment of <b>₹10,000</b>.<br/>"
        "• <b>Pay-Per-Scan Consumption:</b> Charges are deducted strictly when a student scans their QR code at the counter:<br/>"
        "&nbsp;&nbsp;&nbsp;&nbsp;- <b>Breakfast:</b> ₹25 / meal (Mon–Sat) | Sunday Closed (₹0)<br/>"
        "&nbsp;&nbsp;&nbsp;&nbsp;- <b>Lunch:</b> ₹50 / meal (Mon–Sat) | Sunday Special Feast (₹100)<br/>"
        "&nbsp;&nbsp;&nbsp;&nbsp;- <b>Dinner:</b> ₹50 / meal (6 Days) | Wednesday Non-Veg/Paneer Feast (₹100)<br/>"
        "• <b>Net Remaining Deposit:</b> <code>₹10,000 - Total QR Scans Cost</code> dynamically calculated in real time.",
        body_style
    ))

    story.append(Spacer(1, 8))

    # Security & Production Readiness
    story.append(Paragraph("6. Security, Resilience & Privacy Controls", h1_style))
    story.append(Paragraph(
        "• <b>Role-Based Access Control (RBAC):</b> Cryptographically signed JWT tokens with custom claims isolate Students, Mess Managers, and Institute Admins.<br/>"
        "• <b>Immutable Audit Logging:</b> Critical operations (attendance scans, manager approvals, password updates, billing calculations) write append-only logs.<br/>"
        "• <b>Offline & Low-Bandwidth Resilience:</b> Static printable QR codes allow attendance logging even when physical counters lack display screens or power.<br/>"
        "• <b>Data Privacy:</b> Student biometric and contact information is encrypted and strictly scoped to assigned hostel messes.",
        body_style
    ))

    # Build PDF
    doc.build(story, canvasmaker=NumberedCanvas)
    print(f"PDF successfully built at: {pdf_path}")

if __name__ == '__main__':
    base_dir = r"e:\sih"
    diagram_output = os.path.join(base_dir, "smart_mess_architecture_diagram.png")
    pdf_output = os.path.join(base_dir, "Smart_Mess_System_Architecture_and_Tech_Stack.pdf")

    print("1. Generating Architecture Diagram...")
    create_architecture_diagram(diagram_output)

    print("2. Generating Comprehensive PDF Specification...")
    generate_pdf(pdf_output, diagram_output)
    print("Done!")
