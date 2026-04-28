#!/usr/bin/env python3
"""
Generador de PDF para HPCG1-CE02 - Versión mejorada
Convierte el markdown a PDF usando reportlab con mejor formato de tablas
"""

import os
import re
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle, TA_CENTER, TA_JUSTIFY, TA_LEFT
from reportlab.lib.units import inch, cm
from reportlab.lib import colors
from reportlab.platypus import (
    SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle, 
    PageBreak, Preformatted, KeepTogether
)
from reportlab.lib.enums import TA_CENTER, TA_RIGHT, TA_LEFT, TA_JUSTIFY

# Archivos
MD_FILE = "HPCG1-CE02-DavidSantiagoLugoCabrera-JoseAroudoJuniordeAsisPinedo-AngieCarolinaVargasVillegas.md"
PDF_FILE = "HPCG1-CE02-DavidSantiagoLugoCabrera-JoseAroudoJuniordeAsisPinedo-AngieCarolinaVargasVillegas.pdf"

def create_pdf():
    """Create PDF from markdown content"""
    
    # Leer markdown
    if not os.path.exists(MD_FILE):
        print(f"Error: {MD_FILE} no encontrado")
        return False
    
    with open(MD_FILE, 'r', encoding='utf-8') as f:
        md_lines = f.readlines()
    
    # Crear documento PDF
    doc = SimpleDocTemplate(PDF_FILE, pagesize=A4, topMargin=0.75*inch, bottomMargin=0.75*inch)
    story = []
    
    # Estilos
    styles = getSampleStyleSheet()
    
    # Estilos personalizados
    title_style = ParagraphStyle(
        'CustomTitle',
        parent=styles['Heading1'],
        fontSize=28,
        textColor=colors.HexColor('#2c3e50'),
        spaceAfter=6,
        alignment=TA_CENTER,
        fontName='Helvetica-Bold'
    )
    
    heading1_style = ParagraphStyle(
        'CustomHeading1',
        parent=styles['Heading1'],
        fontSize=18,
        textColor=colors.HexColor('#2c3e50'),
        spaceAfter=12,
        spaceBefore=12,
        borderColor=colors.HexColor('#3498db'),
        borderWidth=0,
        borderPadding=10,
        leftIndent=0,
        fontName='Helvetica-Bold'
    )
    
    heading2_style = ParagraphStyle(
        'CustomHeading2',
        parent=styles['Heading2'],
        fontSize=14,
        textColor=colors.HexColor('#34495e'),
        spaceAfter=10,
        spaceBefore=10,
        borderLeft=4,
        borderLeftColor=colors.HexColor('#3498db'),
        borderLeftWidth=3,
        leftIndent=15,
        fontName='Helvetica-Bold'
    )
    
    heading3_style = ParagraphStyle(
        'CustomHeading3',
        parent=styles['Heading3'],
        fontSize=12,
        textColor=colors.HexColor('#7f8c8d'),
        spaceAfter=6,
        spaceBefore=6,
        fontName='Helvetica-Bold'
    )
    
    normal_style = ParagraphStyle(
        'CustomNormal',
        parent=styles['Normal'],
        fontSize=10,
        textColor=colors.HexColor('#2c3e50'),
        spaceAfter=8,
        alignment=TA_JUSTIFY
    )
    
    # Portada
    story.append(Spacer(1, 2*inch))
    story.append(Paragraph("Multiplicación de Matrices en C", title_style))
    story.append(Paragraph("Paralelización con OpenMP", title_style))
    story.append(Spacer(1, 0.5*inch))
    story.append(Paragraph("HPCG1-CE02", ParagraphStyle('Subtitle', parent=styles['Normal'], fontSize=24, alignment=TA_CENTER)))
    story.append(Spacer(1, 1.5*inch))
    story.append(Paragraph("<b>INTEGRANTES</b>", ParagraphStyle('Members', parent=styles['Normal'], fontSize=12, alignment=TA_CENTER)))
    story.append(Spacer(1, 0.2*inch))
    story.append(Paragraph("David Santiago Lugo Cabrera", ParagraphStyle('MemberName', parent=styles['Normal'], fontSize=11, alignment=TA_CENTER)))
    story.append(Paragraph("Jose Aroudo Junior de Asis Pinedo", ParagraphStyle('MemberName', parent=styles['Normal'], fontSize=11, alignment=TA_CENTER)))
    story.append(Paragraph("Angie Carolina Vargas Villegas", ParagraphStyle('MemberName', parent=styles['Normal'], fontSize=11, alignment=TA_CENTER)))
    story.append(PageBreak())
    
    # Procesar contenido
    skip_portada = True
    i = 0
    
    while i < len(md_lines):
        line = md_lines[i].rstrip()
        
        # Skip portada
        if skip_portada:
            if "---" in line:
                skip_portada = False
                i += 1
                continue
            i += 1
            continue
        
        # Encabezados
        if line.startswith("## "):
            text = line[3:]
            story.append(Paragraph(text, heading1_style))
        elif line.startswith("### "):
            text = line[4:]
            story.append(Paragraph(text, heading2_style))
        elif line.startswith("#### "):
            text = line[5:]
            story.append(Paragraph(text, heading3_style))
        # Tablas
        elif line.startswith("|"):
            table_rows = []
            start_idx = i
            
            while i < len(md_lines) and md_lines[i].strip().startswith("|"):
                cells = [cell.strip() for cell in md_lines[i].strip().split("|")[1:-1]]
                if not any("---" in str(cell) for cell in cells):  # Skip separator
                    table_rows.append(cells)
                i += 1
            
            if table_rows:
                # Crear tabla con estilo mejorado
                num_cols = len(table_rows[0])
                # Ancho dinámico: distribuir el ancho de página disponible
                col_width = (7.5 * inch) / num_cols  # 7.5 inches disponibles (con márgenes)
                
                t = Table(table_rows, colWidths=[col_width]*num_cols)
                t.setStyle(TableStyle([
                    # Encabezado
                    ('BACKGROUND', (0, 0), (-1, 0), colors.HexColor('#3498db')),
                    ('TEXTCOLOR', (0, 0), (-1, 0), colors.whitesmoke),
                    ('ALIGN', (0, 0), (-1, -1), 'CENTER'),
                    ('VALIGN', (0, 0), (-1, -1), 'MIDDLE'),
                    ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
                    ('FONTSIZE', (0, 0), (-1, 0), 7.5),
                    ('TOPPADDING', (0, 0), (-1, 0), 12),
                    ('BOTTOMPADDING', (0, 0), (-1, 0), 12),
                    ('LEFTPADDING', (0, 0), (-1, 0), 6),
                    ('RIGHTPADDING', (0, 0), (-1, 0), 6),
                    # Cuerpo
                    ('BACKGROUND', (0, 1), (-1, -1), colors.white),
                    ('GRID', (0, 0), (-1, -1), 0.5, colors.HexColor('#bdc3c7')),
                    ('ROWBACKGROUNDS', (0, 1), (-1, -1), [colors.white, colors.HexColor('#f5f5f5')]),
                    ('FONTSIZE', (0, 1), (-1, -1), 7),
                    ('TOPPADDING', (0, 1), (-1, -1), 9),
                    ('BOTTOMPADDING', (0, 1), (-1, -1), 9),
                    ('LEFTPADDING', (0, 1), (-1, -1), 6),
                    ('RIGHTPADDING', (0, 1), (-1, -1), 6),
                ]))
                story.append(Spacer(1, 0.1*inch))
                story.append(t)
                story.append(Spacer(1, 0.15*inch))
            continue
        # Listas
        elif line.startswith("- "):
            text = line[2:]
            story.append(Paragraph(f"• {text}", normal_style))
        # Párrafos
        elif line.strip():
            # Procesar inline formatting
            text = line
            text = re.sub(r'\*\*(.+?)\*\*', r'<b>\1</b>', text)
            text = re.sub(r'\$\$(.+?)\$\$', r'<i>\1</i>', text)
            text = re.sub(r'\[(.+?)\]\(.+?\)', r'\1', text)  # Remove links
            
            story.append(Paragraph(text, normal_style))
        
        i += 1
    
    # Generar PDF
    try:
        doc.build(story)
        print(f"✓ PDF regenerado exitosamente: {PDF_FILE}")
        return True
    except Exception as e:
        print(f"✗ Error generando PDF: {e}")
        return False

if __name__ == "__main__":
    success = create_pdf()
    exit(0 if success else 1)
