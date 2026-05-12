DELIMITER //



CREATE PROCEDURE usp_FindAvailableBed(
    IN p_dept_id INT,
    OUT p_bed_id INT 
)
BEGIN
    SET p_bed_id = NULL; 
    
    SELECT bed_id INTO p_bed_id
    FROM Beds
    WHERE department_id = p_dept_id AND patient_id IS NULL
    LIMIT 1; 
END //


CREATE PROCEDURE usp_RegisterEmergencyAdmission(
    IN p_patient_id INT,
    IN p_doctor_id INT,
    IN p_dept_id INT,
    IN p_time DATETIME,
    OUT p_message VARCHAR(255)
)
master_logic: BEGIN
    DECLARE v_found_bed_id INT;
    DECLARE v_is_staying INT DEFAULT 0;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_message = 'Hệ thống gặp sự cố kỹ thuật. Đã hoàn nguyên.';
    END;

    START TRANSACTION;

    SELECT COUNT(*) INTO v_is_staying 
    FROM Beds 
    WHERE patient_id = p_patient_id;

    IF v_is_staying > 0 THEN
        SET p_message = 'Từ chối: Bệnh nhân đang lưu trú';
        ROLLBACK;
        LEAVE master_logic;
    END IF;

    CALL usp_FindAvailableBed(p_dept_id, v_found_bed_id);

    IF v_found_bed_id IS NULL THEN
        SET p_message = 'Từ chối: Khoa hiện đã hết giường';
        ROLLBACK;
        LEAVE master_logic;
    END IF;

  
    INSERT INTO Appointments (patient_id, doctor_id, department_id, appointment_time, status)
    VALUES (p_patient_id, p_doctor_id, p_dept_id, p_time, 'In-patient');

    UPDATE Beds 
    SET patient_id = p_patient_id 
    WHERE bed_id = v_found_bed_id;

    COMMIT;
    SET p_message = CONCAT('Thành công: Đã xếp giường ', v_found_bed_id);

END //

DELIMITER ;


CALL usp_RegisterEmergencyAdmission(101, 10, 1, NOW(), @msg); SELECT @msg;

CALL usp_RegisterEmergencyAdmission(102, 11, 5, NOW(), @msg); SELECT @msg;

CALL usp_RegisterEmergencyAdmission(101, 12, 1, NOW(), @msg); SELECT @msg;

CALL usp_RegisterEmergencyAdmission(103, 13, 999, NOW(), @msg); SELECT @msg;
