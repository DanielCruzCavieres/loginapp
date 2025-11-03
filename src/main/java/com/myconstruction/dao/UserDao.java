package com.myconstruction.dao;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.ResultSet;

public class UserDao {

    private static final String URL =
        "jdbc:mysql://localhost:3306/myconstruction?serverTimezone=UTC&useSSL=false&allowPublicKeyRetrieval=true";
    private static final String USER = "root";
    private static final String PASS = "root";

    public boolean isValid(String username, String password) {
        final String sql = "SELECT id FROM usuarios WHERE username=? AND password=?";
        try (Connection cn = DriverManager.getConnection(URL, USER, PASS);
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setString(1, username);
            ps.setString(2, password);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next();
            }
        } catch (Exception ex) {
            // Para la evaluación basta con un log simple
            System.err.println("Error validando usuario: " + ex.getMessage());
            return false;
        }
    }
}