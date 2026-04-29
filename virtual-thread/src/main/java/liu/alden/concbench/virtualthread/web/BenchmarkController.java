package liu.alden.concbench.virtualthread.web;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * @author liuwei
 * @since 2026-04-29 18:07
 */

@RequestMapping("/benchmark")
@RestController
public class BenchmarkController {

    @GetMapping("/sleep")
    public int sleep(int millis) throws InterruptedException {
        Thread.sleep(millis);
        return millis;
    }

}
