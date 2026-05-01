package liu.alden.concbench.j25.threadpool;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * @author liuwei
 * @since 2026-04-29 18:07
 */

@RequestMapping("/benchmark")
@RestController
public class BenchmarkController {

    @GetMapping("/delay/{millis}")
    public int delay(@PathVariable int millis) throws InterruptedException {
        Thread.sleep(millis);
        return millis;
    }

}
